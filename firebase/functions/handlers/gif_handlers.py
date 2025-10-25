"""
GIF generation handlers for Firebase Cloud Functions.
"""
import logging
import json
from firebase_functions import https_fn, options
from firebase_admin import storage
from utils.image_utils import generate_dalle_image, create_animated_gif, cleanup_temp_file
from config import Config

logger = logging.getLogger(__name__)

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=Config.CORS_ORIGINS,
    cors_methods=Config.CORS_METHODS
))
def generate_gif(req: https_fn.Request) -> https_fn.Response:
    """
    Generate a GIF from two DALL-E images.
    
    This function:
    1. Generates 2 images using DALL-E 3
    2. Converts to animated GIF format
    3. Uploads to Firebase Storage
    4. Returns the public URL
    
    Request Body:
    {
        "prompt": "a cat dancing under disco lights"
    }
    
    Response:
    {
        "gif_url": "https://storage.googleapis.com/.../animated.gif",
        "frames_generated": 2
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
        
        logger.info(f"🎬 Generating GIF with prompt: {prompt}")
        
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
        
        # Generate 2 frames with DALL-E
        frames = []
        
        logger.info(f"🎨 Generating 2 frames...")
        
        # Generate frame 1
        try:
            logger.info(f"  🎨 Generating frame 1...")
            frame1 = generate_dalle_image(prompt, "first frame")
            frames.append(frame1)
            logger.info(f"  ✅ Frame 1 generated")
            
        except Exception as e:
            logger.error(f"  ❌ Error generating frame 1: {e}")
            raise Exception(f"Failed to generate frame 1: {e}")
        
        # Generate frame 2
        try:
            logger.info(f"  🎨 Generating frame 2...")
            frame2 = generate_dalle_image(prompt, "second frame, slight variation")
            frames.append(frame2)
            logger.info(f"  ✅ Frame 2 generated")
            
        except Exception as e:
            logger.error(f"  ❌ Error generating frame 2: {e}")
            raise Exception(f"Failed to generate frame 2: {e}")
        
        logger.info(f"✅ Generated 2 frames successfully")
        
        # Convert to GIF
        logger.info("🎞️ Converting to animated GIF format...")
        
        gif_path = create_animated_gif(frames)
        
        logger.info(f"✅ GIF created: {gif_path}")
        
        # Upload to Firebase Storage
        logger.info("☁️ Uploading to Firebase Storage...")
        
        bucket = storage.bucket()
        from datetime import datetime
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        blob_name = f"gifs/generated_{timestamp}.gif"
        blob = bucket.blob(blob_name)
        
        # Upload file
        blob.upload_from_filename(gif_path, content_type="image/gif")
        
        # Make publicly accessible
        blob.make_public()
        
        # Get public URL
        gif_url = blob.public_url
        
        logger.info(f"✅ GIF uploaded: {gif_url}")
        
        # Clean up temp file
        cleanup_temp_file(gif_path)
        
        # Return response
        return https_fn.Response(
            json.dumps({
                "gif_url": gif_url,
                "frames_generated": 2
            }),
            status=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": Config.CORS_ORIGINS
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Error in generate_gif: {e}", exc_info=True)
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": Config.CORS_ORIGINS
            }
        )
