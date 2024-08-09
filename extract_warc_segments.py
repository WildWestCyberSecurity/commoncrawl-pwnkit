import os
import re
import requests
import argparse
from io import BytesIO
from warcio.archiveiterator import ArchiveIterator

def download_warc_segment_by_range(url, offset, length):
    headers = {'Range': f'bytes={offset}-{offset+length-1}'}
    response = requests.get(url, headers=headers, stream=True)
    if response.status_code == 206:  # Partial content response
        return response.content
    else:
        raise Exception(f"Failed to download the WARC segment, status code: {response.status_code}")

def generate_unique_filename(directory, filename):
    base, ext = os.path.splitext(filename)
    counter = 1
    unique_filename = filename
    while os.path.exists(os.path.join(directory, unique_filename)):
        unique_filename = f"{base}_{counter}{ext}"
        counter += 1
    return unique_filename

def extract_content_from_warc_segments(url_list, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    
    for entry in url_list.strip().split('--'):
        original_url_match = re.search(r'Original: (http[^\s]+)', entry)
        warc_url_match = re.search(r'(https[^\s]+)#offset=(\d+)&length=(\d+)', entry)
        
        if original_url_match and warc_url_match:
            original_url = original_url_match.group(1)
            warc_url = warc_url_match.group(1)
            offset = int(warc_url_match.group(2))
            length = int(warc_url_match.group(3))
            
            try:
                warc_segment = download_warc_segment_by_range(warc_url, offset, length)
                archive_iterator = ArchiveIterator(BytesIO(warc_segment))

                for record in archive_iterator:
                    if record.rec_type == 'response':
                        content = record.content_stream().read()
                        filename = generate_unique_filename(output_dir, os.path.basename(original_url))
                        with open(os.path.join(output_dir, filename), 'wb') as f:
                            f.write(content)
                        print(f'Successfully extracted: {filename}')
            except Exception as e:
                print(f"Failed to process {original_url}: {e}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Download specific segments from Common Crawl WARC files and save the content to files.',
        epilog='Example: python script.py -l urls.txt -o ./output_directory'
    )
    parser.add_argument(
        '-l', '--list',
        required=True,
        help='Path to the file containing the list of URLs with offsets and lengths. Each entry should follow the format: "Original: <URL> -- <WARC_URL>#offset=<OFFSET>&length=<LENGTH>"'
    )
    parser.add_argument(
        '-o', '--output',
        required=True,
        help='Directory to save the extracted content. This directory will be created if it does not exist.'
    )

    args = parser.parse_args()

    with open(args.list, 'r') as file:
        url_list = file.read()

    extract_content_from_warc_segments(url_list, args.output)
