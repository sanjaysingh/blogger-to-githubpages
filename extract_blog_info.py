#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
import re

def extract_blog_info(xml_file):
    # Parse the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    # Define namespaces
    namespaces = {
        '': 'http://www.w3.org/2005/Atom',
        'gd': 'http://schemas.google.com/g/2005'
    }
    
    # Extract blog title
    title_elem = root.find('title', namespaces)
    blog_title = title_elem.text if title_elem is not None else "My Blog"
    
    # Extract author information
    author_elem = root.find('author', namespaces)
    author_name = ""
    author_email = ""
    author_image = ""
    
    if author_elem is not None:
        name_elem = author_elem.find('n')
        email_elem = author_elem.find('email')
        image_elem = author_elem.find('gd:image', namespaces)
        
        author_name = name_elem.text if name_elem is not None else "Author"
        author_email = email_elem.text if email_elem is not None else ""
        if image_elem is not None:
            author_image = image_elem.get('src', '')
    
    # Generate Jekyll _config.yml
    config = f"""# Minimal Mistakes Jekyll Theme Configuration

# Site Settings
locale                   : "en-US"
title                    : "{blog_title}"
title_separator          : "-"
subtitle                 : "Migrated from Blogger"
name                     : "{author_name}"
description              : "Personal blog migrated from Blogger"
url                      : ""
baseurl                  : ""
repository               : ""
teaser                   : # path of fallback teaser image
logo                     : # path of logo image to display in the masthead
masthead_title           : # overrides the website title displayed in the masthead
breadcrumbs              : true
words_per_minute         : 200

# Site Author
author:
  name             : "{author_name}"
  avatar           : # path of avatar image
  bio              : "Blogger"
  location         : ""
  email            : "{author_email}"
  links:
    - label: "Email"
      icon: "fas fa-fw fa-envelope-square"
      url: "mailto:{author_email}"

# Site Footer
footer:
  links:
    - label: "GitHub"
      icon: "fab fa-fw fa-github"
    - label: "Twitter"
      icon: "fab fa-fw fa-twitter-square"

# Reading Files
include:
  - .htaccess
  - _pages
exclude:
  - "*.sublime-project"
  - "*.sublime-workspace"
  - vendor
  - .asset-cache
  - .bundle
  - .jekyll-assets-cache
  - .sass-cache
  - assets/js/plugins
  - assets/js/_main.js
  - assets/js/vendor
  - Capfile
  - CHANGELOG
  - config
  - Gemfile
  - Gruntfile.js
  - gulpfile.js
  - LICENSE
  - log
  - node_modules
  - package.json
  - package-lock.json
  - Rakefile
  - README
  - tmp
keep_files:
  - .git
  - .svn
encoding: "utf-8"
markdown_ext: "markdown,mkdown,mkdn,mkd,md"

# Conversion
markdown: kramdown
highlighter: rouge
lsi: false
excerpt_separator: "\\n\\n"
incremental: false

# Markdown Processing
kramdown:
  input: GFM
  hard_wrap: false
  auto_ids: true
  footnote_nr: 1
  entity_output: as_char
  toc_levels: 1..6
  smart_quotes: lsquo,rsquo,ldquo,rdquo
  enable_coderay: false

# Sass/SCSS
sass:
  sass_dir: _sass
  style: compressed # https://sass-lang.com/documentation/file.SASS_REFERENCE.html#output_style

# Outputting
permalink: /:categories/:year/:month/:day/:title/
paginate: 10
paginate_path: /page:num/
timezone: # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

# Plugins
plugins:
  - jekyll-paginate
  - jekyll-sitemap
  - jekyll-gist
  - jekyll-feed
  - jekyll-include-cache

# Archives
category_archive:
  type: liquid
  path: /categories/
tag_archive:
  type: liquid
  path: /tags/

# HTML Compression
compress_html:
  clippings: all
  ignore:
    envs: development

# Defaults
defaults:
  # _posts
  - scope:
      path: ""
      type: posts
    values:
      layout: single
      author_profile: true
      read_time: true
      comments: true
      share: true
      related: true
"""
    return config

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_blog_info.py <blogger_xml_file>")
        sys.exit(1)
    
    xml_file = sys.argv[1]
    config = extract_blog_info(xml_file)
    print(config) 