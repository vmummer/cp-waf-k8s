import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import argparse

visited = set()

def crawl(url, base_url, verbose):
    if url in visited:
        if verbose:
            print(f"[SKIP] Already visited: {url}")
        return
    visited.add(url)

    if verbose:
        print(f"[REQUEST] Fetching: {url}")

    try:
        response = requests.get(url, timeout=10)
        content_type = response.headers.get('Content-Type', '')
        if 'text/html' not in content_type:
            if verbose:
                print(f"[SKIP] Non-HTML content: {url} ({content_type})")
            return

        if verbose:
            print(f"[SUCCESS] Crawled: {url}")

        soup = BeautifulSoup(response.text, 'html.parser')
        for link in soup.find_all('a', href=True):
            href = link['href']
            full_url = urljoin(url, href)
            parsed = urlparse(full_url)
            if parsed.netloc == urlparse(base_url).netloc:
                if verbose:
                    print(f"[FOUND LINK] {full_url}")
                crawl(full_url, base_url, verbose)
            else:
                if verbose:
                    print(f"[SKIP] External link: {full_url}")
    except requests.RequestException as e:
        if verbose:
            print(f"[ERROR] Failed to crawl {url}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simple website crawler with verbose output")
    parser.add_argument("url", help="Starting URL to crawl")
    parser.add_argument("--verbose", action="store_true", help="Show detailed crawling activity")
    args = parser.parse_args()

    crawl(args.url, args.url, args.verbose)

