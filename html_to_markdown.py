#!/usr/bin/env python3
import sys
import os
import re
import html
import glob

def convert_html_to_markdown(content):
    """Convert HTML content to pure markdown using regex"""
    # Remove HTML comments
    content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
    
    # Remove style, script, and other tags that shouldn't be converted
    content = re.sub(r'<style.*?>.*?</style>', '', content, flags=re.DOTALL)
    content = re.sub(r'<script.*?>.*?</script>', '', content, flags=re.DOTALL)
    
    # Convert headings
    for i in range(6, 0, -1):  # Start with h6 to avoid nested replacements
        content = re.sub(r'<h{0}[^>]*>(.*?)</h{0}>'.format(i), r'\n\n' + '#' * i + r' \1\n\n', content, flags=re.DOTALL)
    
    # Convert paragraphs
    content = re.sub(r'<p[^>]*>(.*?)</p>', r'\n\n\1\n\n', content, flags=re.DOTALL)
    
    # Convert line breaks
    content = re.sub(r'<br\s*/?>', r'\n', content)
    
    # Convert bold and strong
    content = re.sub(r'<(b|strong)[^>]*>(.*?)</\1>', r'**\2**', content, flags=re.DOTALL)
    
    # Convert italic and emphasis
    content = re.sub(r'<(i|em)[^>]*>(.*?)</\1>', r'*\2*', content, flags=re.DOTALL)
    
    # Convert links
    content = re.sub(r'<a[^>]*href=[\'"]([^\'"]*)[\'"][^>]*>(.*?)</a>', r'[\2](\1)', content, flags=re.DOTALL)
    
    # Convert images
    content = re.sub(r'<img[^>]*src=[\'"]([^\'"]*)[\'"][^>]*alt=[\'"]([^\'"]*)[\'"][^>]*/?>', r'![\2](\1)', content)
    content = re.sub(r'<img[^>]*alt=[\'"]([^\'"]*)[\'"][^>]*src=[\'"]([^\'"]*)[\'"][^>]*/?>', r'![\1](\2)', content)
    content = re.sub(r'<img[^>]*src=[\'"]([^\'"]*)[\'"][^>]*/?>', r'![](\1)', content)
    
    # Convert unordered lists
    def replace_ul(match):
        ul_content = match.group(1)
        # Replace each li with a bullet point
        ul_content = re.sub(r'<li[^>]*>(.*?)</li>', r'* \1\n', ul_content, flags=re.DOTALL)
        return '\n' + ul_content + '\n'
    
    content = re.sub(r'<ul[^>]*>(.*?)</ul>', replace_ul, content, flags=re.DOTALL)
    
    # Convert ordered lists
    def replace_ol(match):
        ol_content = match.group(1)
        # Split into list items
        items = re.findall(r'<li[^>]*>(.*?)</li>', ol_content, flags=re.DOTALL)
        # Replace each li with a numbered item
        result = '\n'
        for i, item in enumerate(items, 1):
            result += f"{i}. {item.strip()}\n"
        return result + '\n'
    
    content = re.sub(r'<ol[^>]*>(.*?)</ol>', replace_ol, content, flags=re.DOTALL)
    
    # Convert code blocks
    def replace_pre(match):
        code_content = match.group(1)
        # Try to extract language from class attribute
        lang = ""
        lang_match = re.search(r'<pre[^>]*class=[\'"]([^\'"]*)[\'"]', match.group(0))
        if lang_match:
            classes = lang_match.group(1).split()
            for cls in classes:
                if cls.startswith('language-') or cls.startswith('lang-'):
                    lang = cls.split('-', 1)[1]
                    break
        
        # If no language in pre tag, try to find it in code tag
        if not lang:
            code_lang_match = re.search(r'<code[^>]*class=[\'"]([^\'"]*)[\'"]', code_content)
            if code_lang_match:
                classes = code_lang_match.group(1).split()
                for cls in classes:
                    if cls.startswith('language-') or cls.startswith('lang-'):
                        lang = cls.split('-', 1)[1]
                        break
        
        # Remove code tags if present
        code_content = re.sub(r'<code[^>]*>(.*?)</code>', r'\1', code_content, flags=re.DOTALL)
        
        # Return code block with language if found
        if lang:
            return f'\n```{lang}\n{code_content.strip()}\n```\n'
        else:
            return f'\n```\n{code_content.strip()}\n```\n'
    
    content = re.sub(r'<pre[^>]*>(.*?)</pre>', replace_pre, content, flags=re.DOTALL)
    
    # Convert inline code
    content = re.sub(r'<code[^>]*>(.*?)</code>', r'`\1`', content, flags=re.DOTALL)
    
    # Convert blockquotes
    def replace_blockquote(match):
        quote_content = match.group(1)
        # Add > to each line
        lines = quote_content.strip().split('\n')
        result = '\n'
        for line in lines:
            if line.strip():
                result += f"> {line.strip()}\n"
        return result + '\n'
    
    content = re.sub(r'<blockquote[^>]*>(.*?)</blockquote>', replace_blockquote, content, flags=re.DOTALL)
    
    # Remove any remaining HTML tags
    content = re.sub(r'<[^>]*>', '', content)
    
    # Fix multiple newlines
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    # Unescape HTML entities
    content = html.unescape(content)
    
    return content.strip()

def process_markdown_files(directory):
    """Process all markdown files in the given directory and its subdirectories"""
    # Get all markdown files
    md_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))
    
    print(f"Found {len(md_files)} markdown files to process")
    
    for md_file in md_files:
        print(f"Processing {md_file}...")
        
        # Read the file
        with open(md_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Split front matter and content
        parts = content.split('---', 2)
        if len(parts) >= 3:
            front_matter = parts[0] + '---' + parts[1] + '---'
            html_content = parts[2]
        else:
            front_matter = ''
            html_content = content
        
        # Convert HTML to markdown
        markdown_content = convert_html_to_markdown(html_content)
        
        # Write the file back
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(front_matter + '\n\n' + markdown_content)
        
        print(f"Converted {md_file} to pure markdown")
    
    print(f"Processed {len(md_files)} markdown files successfully!")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python html_to_markdown.py <posts_dir>")
        sys.exit(1)
    
    posts_dir = sys.argv[1]
    process_markdown_files(posts_dir) 