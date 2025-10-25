"""
Web scraping and search utilities.
"""
import logging
import requests
from typing import List, Dict
from bs4 import BeautifulSoup
from config import Config

logger = logging.getLogger(__name__)

def search_duckduckgo(query: str, max_results: int = None) -> List[Dict[str, str]]:
    """
    Search DuckDuckGo and return results.
    
    Args:
        query: Search query
        max_results: Maximum number of results to return
        
    Returns:
        List of dicts with 'title', 'url', 'snippet'
    """
    if max_results is None:
        max_results = Config.MAX_SEARCH_RESULTS
        
    try:
        # Use DuckDuckGo HTML search (no API key needed)
        search_url = "https://html.duckduckgo.com/html/"
        params = {
            'q': query,
            'kl': 'us-en'  # Region
        }
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.post(search_url, data=params, headers=headers, timeout=Config.REQUEST_TIMEOUT)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        results = []
        for result_div in soup.find_all('div', class_='result', limit=max_results):
            try:
                # Extract title and URL
                title_tag = result_div.find('a', class_='result__a')
                if not title_tag:
                    continue
                
                title = title_tag.get_text(strip=True)
                url = title_tag.get('href', '')
                
                # Clean URL (DuckDuckGo wraps URLs)
                if url.startswith('//duckduckgo.com/l/?uddg='):
                    # Extract actual URL from redirect
                    import urllib.parse
                    url = urllib.parse.unquote(url.split('uddg=')[1].split('&')[0])
                
                # Extract snippet
                snippet_tag = result_div.find('a', class_='result__snippet')
                snippet = snippet_tag.get_text(strip=True) if snippet_tag else ""
                
                if url and not url.startswith('http'):
                    url = 'https:' + url
                
                results.append({
                    'title': title,
                    'url': url,
                    'snippet': snippet
                })
                
            except Exception as e:
                logger.warning(f"Error parsing search result: {e}")
                continue
        
        return results
        
    except Exception as e:
        logger.error(f"Error searching DuckDuckGo: {e}")
        return []


def scrape_webpage(url: str, timeout: int = None) -> str:
    """
    Scrape text content from a webpage.
    
    Args:
        url: URL to scrape
        timeout: Request timeout in seconds
        
    Returns:
        Text content of the page
    """
    if timeout is None:
        timeout = Config.REQUEST_TIMEOUT
        
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Remove script and style elements
        for script in soup(['script', 'style', 'nav', 'footer', 'header']):
            script.decompose()
        
        # Get text
        text = soup.get_text(separator=' ', strip=True)
        
        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        return text
        
    except Exception as e:
        logger.error(f"Error scraping {url}: {e}")
        return ""
