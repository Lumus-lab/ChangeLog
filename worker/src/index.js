export default {
    async fetch(request, env, ctx) {
        const corsHeaders = {
            'Access-Control-Allow-Origin': '*', // IMPORTANT: Change this to your specific App domain or restrict via App Check
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
            // 1. App Validation & Security
            // In a real scenario, you can check headers like `app-id` or use Cloudflare App Check
            const appId = request.headers.get('app-id');
            if (appId !== env.EXPECTED_APP_ID) {
                return new Response(JSON.stringify({ error: 'Unauthorized request origin.' }), { status: 403, headers: corsHeaders });
            }

            const body = await request.json();
            const { primaryHex, resultingHex, guidance, question, adToken } = body;

            // 2. Validate Ad Token
            if (!adToken) {
                return new Response(JSON.stringify({ error: 'Ad verification failed.' }), { status: 403, headers: corsHeaders });
            }

            // 3. Cache Check (KV)
            // Cache key based on primary, resulting and question
            const cacheKey = `hex_${primaryHex}_res_${resultingHex || 'none'}_q_${question.toLowerCase().trim().replace(/\s+/g, '_')}`;

            const cachedResponse = await env.HEXAGRAM_CACHE.get(cacheKey);
            if (cachedResponse) {
                return new Response(cachedResponse, {
                    headers: { ...corsHeaders, 'Content-Type': 'application/json', 'X-Cache': 'HIT' }
                });
            }

            // 4. Call Gemini 3.1 Flash-Lite
            if (!env.GEMINI_API_KEY) {
                throw new Error('GEMINI_API_KEY is not configured in Cloudflare Secrets.');
            }

            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=${env.GEMINI_API_KEY}`;

            const hexInfo = resultingHex ?
                `本卦為「${primaryHex}」，變卦為「${resultingHex}」` :
                `卦象為「${primaryHex}」（無變爻）`;

            const prompt = `你是一個結合易經智慧與現代管理思維的 AI 解析助手。
            使用者求問：「${question}」
            抽到的卦象顯示：${hexInfo}。
            
            根據傳統朱熹解卦法則判讀建議如下（請務必以此作為核心分析點）：
            「${guidance}」
            
            規範：
            1. 不要自我介紹（例如：不要說「你好，我是命理師」）。
            2. 採用以下開場格式：「針對您求問的『${question}』，目前的卦象呈現為『${primaryHex}』...」
            3. 使用標準 Markdown 格式：
               - 粗體使用 **文字**（星號與內部文字之間不可有空格）。
               - 列表使用 - 或 * 開頭。
               - 標題使用 ###。
            4. 語氣溫和、有建設性。
            5. 請務必尊重上面判讀建議中的爻位訊息（例如「九五爻動」或「初六爻動」），強烈禁止自行臆測或更改變爻的位置。
            
            請提供簡潔且具洞察力的解卦。`;

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

            // 5. Save to Cache KV (Expiration to prevent stale data or save space, e.g. 30 days)
            ctx.waitUntil(env.HEXAGRAM_CACHE.put(cacheKey, responsePayload, { expirationTtl: 2592000 })); // 30 days in seconds

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
