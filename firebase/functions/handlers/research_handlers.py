"""
Web research handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn, options
from utils.web_utils import search_duckduckgo, scrape_webpage
from utils.ai_utils import generate_ai_response
from config import Config
from prompts import RESEARCH_SYSTEM_PROMPT, get_research_user_prompt

logger = logging.getLogger(__name__)

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def conduct_research(req: https_fn.Request) -> https_fn.Response:
    """
    Conduct web research on a given prompt.
    
    This function:
    1. Searches DuckDuckGo for relevant information
    2. Scrapes content from top results
    3. Uses OpenAI GPT to summarize the findings
    4. Returns a comprehensive summary
    
    Request Body:
    {
        "prompt": "What are the latest developments in renewable energy?"
    }
    
    Response:
    {
        "summary": "Based on recent research...",
        "sources": [{"title": "...", "url": "..."}]
    }
    """
    try:
        # Handle CORS preflight
        if req.method == "OPTIONS":
            return https_fn.Response(
                status=204,
                headers={
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS,
                    "Access-Control-Allow-Methods": ", ".join(Config.CORS_METHODS),
                    "Access-Control-Allow-Headers": Config.CORS_HEADERS,
                    "Access-Control-Max-Age": Config.CORS_MAX_AGE
                }
            )
        
        # Parse request
        data = req.get_json()
        
        if not data or "prompt" not in data:
            return https_fn.Response(
                json.dumps({"error": "Missing 'prompt' in request body"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS
                }
            )
        
        prompt = data.get("prompt")
        
        if not prompt or len(prompt.strip()) == 0:
            return https_fn.Response(
                json.dumps({"error": "Prompt cannot be empty"}),
                status=400,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS
                }
            )
        
        logger.info(f"🔍 Conducting research: {prompt}")
        
        if not Config.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not set in environment")
            return https_fn.Response(
                json.dumps({"error": "OpenAI API key not configured"}),
                status=500,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS
                }
            )
        
        # Step 1: Search DuckDuckGo for results
        logger.info("🌐 Searching DuckDuckGo...")
        search_results = search_duckduckgo(prompt)
        
        if not search_results:
            logger.warning("No search results found")
            return https_fn.Response(
                json.dumps({
                    "summary": "I couldn't find any relevant information for your query. Please try rephrasing your question or search for something else."
                }),
                status=200,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS
                }
            )
        
        logger.info(f"✅ Found {len(search_results)} search results")
        
        # Step 2: Scrape content from top results (limit to 3)
        logger.info("📄 Scraping content from top results...")
        scraped_content = []
        for i, result in enumerate(search_results[:3]):
            try:
                content = scrape_webpage(result['url'])
                if content:
                    scraped_content.append({
                        'title': result['title'],
                        'url': result['url'],
                        'content': content[:Config.MAX_SCRAPED_CONTENT_LENGTH]  # Limit content length
                    })
                    logger.info(f"  ✅ Scraped: {result['title']}")
            except Exception as e:
                logger.warning(f"  ❌ Failed to scrape {result['url']}: {e}")
                continue
        
        if not scraped_content:
            logger.warning("No content could be scraped")
            return https_fn.Response(
                json.dumps({
                    "summary": "I found some results but couldn't access their content. This might be due to website restrictions. Please try a different query."
                }),
                status=200,
                headers={
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": Config.CORS_ORIGINS
                }
            )
        
        logger.info(f"✅ Scraped {len(scraped_content)} pages")
        
        # Step 3: Use OpenAI to summarize the findings
        logger.info("🤖 Generating AI summary...")
        
        # Prepare context for AI
        context = "\n\n".join([
            f"Source: {item['title']}\nURL: {item['url']}\nContent: {item['content']}"
            for item in scraped_content
        ])
        
        # Create LangChain prompt
        system_prompt = RESEARCH_SYSTEM_PROMPT
        user_prompt = get_research_user_prompt(prompt, context)
        
        summary = generate_ai_response(system_prompt, user_prompt, temperature=0.7)
        
        logger.info(f"✅ Research complete!")
        logger.info(f"   Summary length: {len(summary)} characters")
        
        # Return response
        return https_fn.Response(
            json.dumps({
                "summary": summary,
                "sources": [{"title": item['title'], "url": item['url']} for item in scraped_content]
            }),
            status=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": Config.CORS_ORIGINS
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Error in conduct_research: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": Config.CORS_ORIGINS
            }
        )
