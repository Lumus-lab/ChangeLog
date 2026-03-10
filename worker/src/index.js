export default {
    async fetch(request, env, ctx) {
        const corsHeaders = {
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, app-id, authorization',
        };

        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        if (request.method !== 'POST') {
            return new Response('Method Not Allowed', { status: 405, headers: corsHeaders });
        }

        try {
            // 1. App Validation
            const appId = request.headers.get('app-id');
            if (appId !== env.EXPECTED_APP_ID) {
                return new Response(JSON.stringify({ error: 'Unauthorized request origin.' }), { status: 403, headers: corsHeaders });
            }

            const body = await request.json();
            const { prompt, adToken } = body;

            // 2. Validate Ad Token
            if (!adToken) {
                return new Response(JSON.stringify({ error: 'Ad verification failed.' }), { status: 403, headers: corsHeaders });
            }

            // 3. Validate prompt
            if (!prompt) {
                return new Response(JSON.stringify({ error: 'Missing prompt.' }), { status: 400, headers: corsHeaders });
            }

            // 4. Cache Check (KV) — 使用 prompt 的 SHA-256 hash 作為 cache key
            const encoder = new TextEncoder();
            const data = encoder.encode(prompt);
            const hashBuffer = await crypto.subtle.digest('SHA-256', data);
            const hashArray = Array.from(new Uint8Array(hashBuffer));
            const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
            const cacheKey = `prompt_${hashHex}`;

            const cachedResponse = await env.HEXAGRAM_CACHE.get(cacheKey);
            if (cachedResponse) {
                return new Response(cachedResponse, {
                    headers: { ...corsHeaders, 'Content-Type': 'application/json', 'X-Cache': 'HIT' }
                });
            }

            // 5. Call Gemini — Worker 只負責轉發，不自己組 prompt
            if (!env.GEMINI_API_KEY) {
                throw new Error('GEMINI_API_KEY is not configured in Cloudflare Secrets.');
            }

            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${env.GEMINI_API_KEY}`;

            const geminiResponse = await fetch(geminiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }]
                })
            });

            if (!geminiResponse.ok) {
                const errorText = await geminiResponse.text();
                throw new Error(`Gemini API Error: ${errorText}`);
            }

            const geminiData = await geminiResponse.json();

            // Parse out the text from Gemini response
            let interpretation = "";
            try {
                interpretation = geminiData.candidates[0].content.parts[0].text;
            } catch (e) {
                throw new Error("Failed to parse Gemini response formatting.");
            }

            const responsePayload = JSON.stringify({ interpretation });

            // 6. Save to Cache KV (30 days)
            ctx.waitUntil(env.HEXAGRAM_CACHE.put(cacheKey, responsePayload, { expirationTtl: 2592000 }));

            return new Response(responsePayload, {
                headers: { ...corsHeaders, 'Content-Type': 'application/json', 'X-Cache': 'MISS' }
            });

        } catch (error) {
            return new Response(JSON.stringify({ error: error.message }), {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }
    }
};
