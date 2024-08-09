# 🕸️ commoncrawl-pwnkit

**Unleash your power over web archives with `commoncrawl-pwnkit`!** 

This repository equips you with the tools you need to dominate the vast web archives of Common Crawl. Whether you're diving deep into historical web data, extracting specific content, or conducting security research, `commoncrawl-pwnkit` is your ultimate toolkit.

## 🚀 What’s Inside?

### 1. `common_crawl_pwn.sh`
- **🎯 Purpose**: This Bash script is your go-to for extracting metadata from Common Crawl based on specific domains. Whether you have a list of domains or a single target, `common_crawl_pwn.sh` helps you fetch metadata efficiently and generates complete URLs for easy access to archived content.
- **✨ Features**:
  - Extract metadata for multiple domains or a single domain.
  - Optionally include wildcard subdomains.
  - Retrieve and format metadata for easy analysis.
- **🛠️ Usage**:
  ```bash
  ./common_crawl_pwn.sh -d domains.txt -o output_file.csv
  ```
  - **📋 Arguments**:
    - `-d`: Path to a file containing a list of domains.
    - `-t`: Specify a single target domain.
    - `-o`: Output file where the metadata and URLs will be saved.
    - `-w`: (Optional) Include wildcard subdomains in the search.

### 2. `extract_warc_segments.py`
- **🎯 Purpose**: A Python script designed to download specific segments from Common Crawl WARC files based on byte offsets and lengths. `extract_warc_segments.py` lets you efficiently extract and save content like PDFs, HTML, or any other web data you need.
- **✨ Features**:
  - Download content from precise locations within WARC files.
  - Save extracted data with unique filenames to avoid overwriting.
  - Handle large web archives with ease.
- **🛠️ Usage**:
  ```bash
  python extract_warc_segments.py -l urls.txt -o ./output_directory
  ```
  - **📋 Arguments**:
    - `-l`: Path to a file containing a list of URLs with offsets and lengths.
    - `-o`: Directory where the extracted content will be saved.

## 📂 How to Get Started

1. **💾 Clone the repository**:
   ```bash
   git clone https://github.com/WildWestCyberSecurity/commoncrawl-pwnkit.git
   ```

2. **🔍 Navigate to the directory**:
   ```bash
   cd commoncrawl-pwnkit
   ```

3. **🚀 Run the scripts** with your data:
   - Use `common_crawl_pwn.sh` to extract metadata from specific domains.
   - Use `extract_warc_segments.py` to download and save content from WARC files.

## 🛠️ Requirements

Make sure to install the necessary dependencies before running the Python script:

```plaintext
requests==2.31.0
warcio==1.7.4
```

Install them via pip:
```bash
pip install -r requirements.txt
```

## 📄 License

This project is licensed under the MIT License.

---

**Happy web archiving/bug hunting! 🕵️‍♂️**
