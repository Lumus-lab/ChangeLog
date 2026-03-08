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

            const prompt = `你是一位深研《易經》哲學的引導者。你的目標不是「算命」或「給予具體建議」，而是透過卦象中蘊含的「時」與「位」的動態智慧，引發使用者深度思考，從而發現自己的路。
            
            使用者求問：「${question}」
            卦象顯示：${hexInfo}。
            根據朱熹解卦法則，目前的觀測重心為：「${guidance}」
            
            請遵循以下原則進行解析：
            1. **絕對不要給予直接的建議或指令。** 你的任務是客觀解釋現狀的「動態性質」。
            2. **著重分析「時 (Timing)」與「位 (Position)」**。目前的情境是屬於積蓄力量、等待時機、還是該順勢而為？使用者的內在狀態與外在環境處於什麼樣的相對位置？
            3. **啟發與發現**。用溫和且富有哲理的白話，解析卦象如何對映使用者的問題。
            4. **格式規範**：
               - 不要自我介紹。
               - 開場請用：「針對您求問的『${question}』，目前的卦象呈現為『${primaryHex}』...」
               - 使用標準 Markdown 格式（**粗體**、### 標題）。
               - 最後必須提出一個「反思性提問」，讓使用者自己決定下一步。
            5. **篇幅限制**：解析字數不超過 350 字。`;

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
