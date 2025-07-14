import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import argparse

visited = set()

def crawl(url, base_url, verbose):
    if url in visited:
        return
    visited.add(url)
    if verbose:
        print(f"Crawling: {url}")

    try:
        response = requests.get(url, timeout=10)
        if 'text/html' not in response.headers.get('Content-Type', ''):
            return
        soup = BeautifulSoup(response.text, 'html.parser')
        for link in soup.find_all('a', href=True):
            href = link['href']
            full_url = urljoin(url, href)
            parsed = urlparse(full_url)
            if parsed.netloc == urlparse(base_url).netloc:
                crawl(full_url, base_url, verbose)
    except requests.RequestException as e:
        if verbose:
            print(f"Failed to crawl {url}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simple website crawler")
    parser.add_argument("url", help="Starting URL to crawl")
    parser.add_argument("--verbose", action="store_true", help="Print URLs as they are crawled")
    args = parser.parse_args()

    crawl(args.url, args.url, args.verbose)

