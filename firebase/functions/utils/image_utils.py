"""
Image processing utilities for GIF generation.
"""
import logging
import io
import tempfile
import os
from typing import List
from PIL import Image
import requests
from openai import OpenAI
from config import Config

logger = logging.getLogger(__name__)

def generate_dalle_image(prompt: str, frame_description: str = "") -> Image.Image:
    """
    Generate an image using DALL-E.
    
    Args:
        prompt: Base prompt for the image
        frame_description: Additional description for the frame
        
    Returns:
        PIL Image object
    """
    try:
        client = OpenAI(api_key=Config.OPENAI_API_KEY)
        
        full_prompt = f"{prompt}, {frame_description}" if frame_description else prompt
        
        response = client.images.generate(
            model=Config.DALL_E_MODEL,
            prompt=full_prompt,
            size=Config.IMAGE_SIZE,
            quality="standard",
            n=1
        )
        
        # Get image URL
        image_url = response.data[0].url
        
        # Download image
        img_response = requests.get(image_url)
        img_response.raise_for_status()
        
        # Load image
        img = Image.open(io.BytesIO(img_response.content))
        
        # Resize to optimize GIF size
        img = img.resize(Config.GIF_FRAME_SIZE, Image.Resampling.LANCZOS)
        
        return img
        
    except Exception as e:
        logger.error(f"Error generating DALL-E image: {e}")
        raise

def create_animated_gif(frames: List[Image.Image], duration: int = None) -> str:
    """
    Create an animated GIF from a list of frames.
    
    Args:
        frames: List of PIL Image objects
        duration: Duration per frame in milliseconds
        
    Returns:
        Path to the created GIF file
    """
    if duration is None:
        duration = Config.GIF_DURATION
        
    try:
        with tempfile.NamedTemporaryFile(suffix=".gif", delete=False) as temp_file:
            gif_path = temp_file.name
            
            # Save as animated GIF
            frames[0].save(
                gif_path,
                format='GIF',
                save_all=True,
                append_images=frames[1:],
                duration=duration,
                loop=0,  # Loop forever
                optimize=False
            )
        
        return gif_path
        
    except Exception as e:
        logger.error(f"Error creating animated GIF: {e}")
        raise

def cleanup_temp_file(file_path: str) -> None:
    """
    Clean up a temporary file.
    
    Args:
        file_path: Path to the file to delete
    """
    try:
        if os.path.exists(file_path):
            os.unlink(file_path)
    except Exception as e:
        logger.warning(f"Error cleaning up temp file {file_path}: {e}")
