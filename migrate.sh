#!/bin/bash
set -e

BLOG_XML="/app/sample-blog.xml"
JEKYLL_SITE="/app/jekyll_site"
IMAGES_DIR="${JEKYLL_SITE}/assets/images"
POSTS_DIR="${JEKYLL_SITE}/_posts"

# Clean up any existing files from previous runs
echo "Cleaning up any existing files from previous runs..."
if [ -d "${JEKYLL_SITE}" ]; then
  rm -rf "${JEKYLL_SITE}"
fi

echo "Setting up Jekyll site with Minimal Mistakes theme..."

# Create a new Jekyll site with Minimal Mistakes theme (one of the most popular Jekyll themes)
git clone https://github.com/mmistakes/minimal-mistakes.git ${JEKYLL_SITE}
cd ${JEKYLL_SITE}

# Remove unnecessary files
rm -rf .git .github test CHANGELOG.md README.md screenshot*.png

# Remove sample posts and pages from the theme
echo "Removing sample posts and documentation from the theme..."
rm -rf ${JEKYLL_SITE}/docs
rm -rf ${JEKYLL_SITE}/_posts
rm -rf ${JEKYLL_SITE}/_pages
rm -rf ${JEKYLL_SITE}/_data/ui-text.yml
rm -rf ${JEKYLL_SITE}/index.html

# Create necessary directories
mkdir -p ${IMAGES_DIR}
mkdir -p ${POSTS_DIR}
mkdir -p ${JEKYLL_SITE}/_includes/archive-single
mkdir -p ${JEKYLL_SITE}/_layouts
mkdir -p ${JEKYLL_SITE}/assets/css

# Create a custom archive-single template to show date instead of read time
cat > ${JEKYLL_SITE}/_includes/archive-single/title.html <<EOL
{% if post.date %}
  <p class="page__meta"><i class="far fa-calendar-alt" aria-hidden="true"></i> {{ post.date | date: "%B %d, %Y" }}</p>
{% endif %}
EOL

# Create a custom single layout with wider content
cat > ${JEKYLL_SITE}/_layouts/single.html <<EOL
---
layout: default
---

{% if page.header.overlay_color or page.header.overlay_image or page.header.image %}
  {% include page__hero.html %}
{% elsif page.header.video.id and page.header.video.provider %}
  {% include page__hero_video.html %}
{% endif %}

{% assign breadcrumbs_enabled = site.breadcrumbs %}
{% if page.breadcrumbs != null %}
  {% assign breadcrumbs_enabled = page.breadcrumbs %}
{% endif %}
{% if page.url != "/" and breadcrumbs_enabled %}
  {% include breadcrumbs.html %}
{% endif %}

<div id="main" role="main">
  {% include sidebar.html %}

  <article class="page h-entry" itemscope itemtype="https://schema.org/CreativeWork">
    {% if page.title %}<meta itemprop="headline" content="{{ page.title | markdownify | strip_html | strip_newlines | escape_once }}">{% endif %}
    {% if page.excerpt %}<meta itemprop="description" content="{{ page.excerpt | markdownify | strip_html | strip_newlines | escape_once }}">{% endif %}
    {% if page.date %}<meta itemprop="datePublished" content="{{ page.date | date_to_xmlschema }}">{% endif %}
    {% if page.last_modified_at %}<meta itemprop="dateModified" content="{{ page.last_modified_at | date_to_xmlschema }}">{% endif %}

    <div class="page__inner-wrap">
      {% unless page.header.overlay_color or page.header.overlay_image %}
        <header>
          {% if page.title %}<h1 id="page-title" class="page__title p-name" itemprop="headline">
            <a href="{{ page.url | absolute_url }}" class="u-url" itemprop="url">{{ page.title | markdownify | remove: "<p>" | remove: "</p>" }}</a>
          </h1>{% endif %}
          {% if page.show_date %}
            <p class="page__meta"><i class="far fa-calendar-alt" aria-hidden="true"></i> {{ page.date | date: "%B %d, %Y" }}</p>
          {% endif %}
          {% if page.read_time %}
            <p class="page__meta"><i class="far fa-clock" aria-hidden="true"></i> {% include read-time.html %}</p>
          {% endif %}
        </header>
      {% endunless %}

      <section class="page__content e-content" itemprop="text">
        {% if page.toc %}
          <aside class="sidebar__right {% if page.toc_sticky %}sticky{% endif %}">
            <nav class="toc">
              <header><h4 class="nav__title"><i class="fas fa-{{ page.toc_icon | default: 'file-alt' }}"></i> {{ page.toc_label | default: site.data.ui-text[site.locale].toc_label | default: "On this page" }}</h4></header>
              {% include toc.html sanitize=true html=content h_min=1 h_max=6 class="toc__menu" skip_no_ids=true %}
            </nav>
          </aside>
        {% endif %}
        {{ content }}
        {% if page.link %}<div><a href="{{ page.link }}" class="btn btn--primary">{{ site.data.ui-text[site.locale].ext_link_label | default: "Direct Link" }}</a></div>{% endif %}
      </section>

      <footer class="page__meta">
        {% if site.data.ui-text[site.locale].meta_label %}
          <h4 class="page__meta-title">{{ site.data.ui-text[site.locale].meta_label }}</h4>
        {% endif %}
        {% include page__taxonomy.html %}
        {% include page__date.html %}
      </footer>

      {% if page.share %}{% include social-share.html %}{% endif %}

      {% include post_pagination.html %}
    </div>

    {% if jekyll.environment == 'production' and site.comments.provider and page.comments %}
      {% include comments.html %}
    {% endif %}
  </article>

  {% comment %}<!-- only show related on a post page when `related: true` -->{% endcomment %}
  {% if page.id and page.related and site.related_posts.size > 0 %}
    <div class="page__related">
      <h2 class="page__related-title">{{ site.data.ui-text[site.locale].related_label | default: "You May Also Enjoy" }}</h2>
      <div class="grid__wrapper">
        {% for post in site.related_posts limit:4 %}
          {% include archive-single.html type="grid" %}
        {% endfor %}
      </div>
    </div>
  {% comment %}<!-- otherwise show recent posts if no related when `related: true` -->{% endcomment %}
  {% elsif page.id and page.related %}
    <div class="page__related">
      <h2 class="page__related-title">{{ site.data.ui-text[site.locale].related_label | default: "You May Also Enjoy" }}</h2>
      <div class="grid__wrapper">
        {% for post in site.posts limit:4 %}
          {% if post.id == page.id %}
            {% continue %}
          {% endif %}
          {% include archive-single.html type="grid" %}
        {% endfor %}
      </div>
    </div>
  {% endif %}
</div>
EOL

# Create custom CSS for wider content
cat > ${JEKYLL_SITE}/assets/css/main.scss <<EOL
---
# Only the main Sass file needs front matter (the dashes are enough)
search: false
---

@charset "utf-8";

@import "minimal-mistakes/skins/{{ site.minimal_mistakes_skin | default: 'default' }}"; // skin
@import "minimal-mistakes"; // main partials

// Wider content area
.page {
  width: 100%;
  padding-right: 0;
  @include breakpoint(\$large) {
    width: 90%;
    padding-right: 0;
  }
}

.wide .page {
  @include breakpoint(\$large) {
    padding-right: 0;
  }

  @include breakpoint(\$x-large) {
    padding-right: 0;
  }
}

// Improve post display on home page
.archive__item-title {
  margin-top: 0.5em;
  font-size: 1.5em;
}

.archive__item-excerpt {
  margin-top: 1em;
  font-size: 1em;
  line-height: 1.8;
  
  p {
    margin-bottom: 1em;
    font-size: 1em;
    line-height: 1.8;
  }
  
  h1, h2, h3, h4, h5, h6 {
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    font-weight: bold;
  }
  
  h1 { font-size: 1.5em; }
  h2 { font-size: 1.35em; }
  h3 { font-size: 1.2em; }
  h4 { font-size: 1.1em; }
  
  img {
    max-width: 100%;
    margin: 1em 0;
  }
  
  code, pre {
    font-family: Monaco, Consolas, "Lucida Console", monospace;
    font-size: 0.9em;
  }
  
  pre {
    margin: 1em 0;
    padding: 1em;
    background-color: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 4px;
    overflow-x: auto;
    color: #333;
  }
  
  blockquote {
    margin: 1em 0;
    padding: 0.5em 1em;
    border-left: 0.25em solid #ddd;
    color: #666;
  }
  
  ul, ol {
    margin: 1em 0;
    padding-left: 2em;
  }
  
  div.highlighter-rouge, figure.highlight {
    background-color: #f8f9fa;
    color: #333;
    border-radius: 4px;
    margin-bottom: 1em;
  }
  
  .highlight {
    background-color: #f8f9fa;
    color: #333;
  }
  
  .highlight pre {
    background-color: #f8f9fa;
    color: #333;
    margin: 0;
    padding: 1em;
  }
  
  code {
    background-color: #f1f3f5;
    padding: 0.2em 0.4em;
    border-radius: 3px;
    color: #333;
  }
}

// Consistent post content styling
.page__content {
  p, li, dl {
    font-size: 1em;
    line-height: 1.8;
  }
  
  h1, h2, h3, h4, h5, h6 {
    font-weight: bold;
  }
  
  img {
    max-width: 100%;
    margin: 1em 0;
  }
  
  code, pre {
    font-family: Monaco, Consolas, "Lucida Console", monospace;
    font-size: 0.9em;
  }
}

// Improve list post display
.list__item {
  margin-bottom: 3em;
  
  .page__meta {
    margin: 0.5em 0;
    font-size: 0.8em;
  }
}

// Add pagination styling
.pagination {
  margin: 3em 0;
  text-align: center;
  
  ul {
    display: flex;
    justify-content: center;
    list-style-type: none;
    margin: 0;
    padding: 0;
  }
  
  li {
    margin: 0 0.5em;
  }
}

div.highlighter-rouge, figure.highlight {
  background-color: #f8f9fa;
  color: #333;
  border-radius: 4px;
  margin-bottom: 1em;
}

.highlight {
  background-color: #f8f9fa;
  color: #333;
}

.highlight pre {
  background-color: #f8f9fa;
  color: #333;
}

.highlight .hll { background-color: #f8f9fa; }
.highlight .c { color: #998; font-style: italic; } /* Comment */
.highlight .err { color: #a61717; } /* Error */
.highlight .k { color: #000; font-weight: bold; } /* Keyword */
.highlight .o { color: #000; font-weight: bold; } /* Operator */
.highlight .cm { color: #998; font-style: italic; } /* Comment.Multiline */
.highlight .cp { color: #999; font-weight: bold; } /* Comment.Preproc */
.highlight .c1 { color: #998; font-style: italic; } /* Comment.Single */
.highlight .cs { color: #999; font-weight: bold; font-style: italic; } /* Comment.Special */
.highlight .gd { color: #000; background-color: #fdd; } /* Generic.Deleted */
.highlight .gd .x { color: #000; background-color: #faa; } /* Generic.Deleted.Specific */
.highlight .ge { font-style: italic; } /* Generic.Emph */
.highlight .gr { color: #a00; } /* Generic.Error */
.highlight .gh { color: #999; } /* Generic.Heading */
.highlight .gi { color: #000; background-color: #dfd; } /* Generic.Inserted */
.highlight .gi .x { color: #000; background-color: #afa; } /* Generic.Inserted.Specific */
.highlight .go { color: #888; } /* Generic.Output */
.highlight .gp { color: #555; } /* Generic.Prompt */
.highlight .gs { font-weight: bold; } /* Generic.Strong */
.highlight .gu { color: #aaa; } /* Generic.Subheading */
.highlight .gt { color: #a00; } /* Generic.Traceback */
.highlight .kc { color: #000; font-weight: bold; } /* Keyword.Constant */
.highlight .kd { color: #000; font-weight: bold; } /* Keyword.Declaration */
.highlight .kp { color: #000; font-weight: bold; } /* Keyword.Pseudo */
.highlight .kr { color: #000; font-weight: bold; } /* Keyword.Reserved */
.highlight .kt { color: #458; font-weight: bold; } /* Keyword.Type */
.highlight .m { color: #099; } /* Literal.Number */
.highlight .s { color: #d14; } /* Literal.String */
.highlight .na { color: #008080; } /* Name.Attribute */
.highlight .nb { color: #0086B3; } /* Name.Builtin */
.highlight .nc { color: #458; font-weight: bold; } /* Name.Class */
.highlight .no { color: #008080; } /* Name.Constant */
.highlight .ni { color: #800080; } /* Name.Entity */
.highlight .ne { color: #900; font-weight: bold; } /* Name.Exception */
.highlight .nf { color: #900; font-weight: bold; } /* Name.Function */
.highlight .nn { color: #555; } /* Name.Namespace */
.highlight .nt { color: #000080; } /* Name.Tag */
.highlight .nv { color: #008080; } /* Name.Variable */
.highlight .ow { color: #000; font-weight: bold; } /* Operator.Word */
.highlight .w { color: #bbb; } /* Text.Whitespace */
.highlight .mf { color: #099; } /* Literal.Number.Float */
.highlight .mh { color: #099; } /* Literal.Number.Hex */
.highlight .mi { color: #099; } /* Literal.Number.Integer */
.highlight .mo { color: #099; } /* Literal.Number.Oct */
.highlight .sb { color: #d14; } /* Literal.String.Backtick */
.highlight .sc { color: #d14; } /* Literal.String.Char */
.highlight .sd { color: #d14; } /* Literal.String.Doc */
.highlight .s2 { color: #d14; } /* Literal.String.Double */
.highlight .se { color: #d14; } /* Literal.String.Escape */
.highlight .sh { color: #d14; } /* Literal.String.Heredoc */
.highlight .si { color: #d14; } /* Literal.String.Interpol */
.highlight .sx { color: #d14; } /* Literal.String.Other */
.highlight .sr { color: #009926; } /* Literal.String.Regex */
.highlight .s1 { color: #d14; } /* Literal.String.Single */
.highlight .ss { color: #990073; } /* Literal.String.Symbol */
.highlight .bp { color: #999; } /* Name.Builtin.Pseudo */
.highlight .vc { color: #008080; } /* Name.Variable.Class */
.highlight .vg { color: #008080; } /* Name.Variable.Global */
.highlight .vi { color: #008080; } /* Name.Variable.Instance */
.highlight .il { color: #099; } /* Literal.Number.Integer.Long */

code {
  background-color: #f1f3f5;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  color: #333;
  font-size: 0.9em;
}

// Fix for code blocks on home page
.entries-list .archive__item-excerpt,
.archive__item-excerpt {
  div.language-plaintext.highlighter-rouge,
  div.highlighter-rouge, 
  figure.highlight {
    position: relative;
    background-color: #f8f9fa !important;
    color: #333 !important;
    border: 1px solid #e9ecef;
    border-radius: 4px;
    margin-bottom: 1em;
    overflow-x: auto;
  }
  
  .highlight {
    background-color: #f8f9fa !important;
    color: #333 !important;
  }
  
  .highlight pre {
    background-color: #f8f9fa !important;
    color: #333 !important;
    margin: 0;
    padding: 1em;
  }
  
  pre.highlight {
    background-color: #f8f9fa !important;
    color: #333 !important;
    margin: 0;
    padding: 1em;
    border: none;
  }
  
  pre {
    background-color: #f8f9fa !important;
    border: 1px solid #e9ecef;
    border-radius: 4px;
    padding: 1em;
    margin: 1em 0;
    overflow-x: auto;
    color: #333 !important;
  }
  
  code {
    background-color: #f1f3f5;
    padding: 0.2em 0.4em;
    border-radius: 3px;
    color: #333 !important;
    font-size: 0.9em;
  }
  
  .highlight code {
    background-color: transparent;
    padding: 0;
    border-radius: 0;
  }
}

// Syntax highlighting
.highlight .hll { background-color: #f8f9fa; }
.highlight .c { color: #998; font-style: italic; } /* Comment */
.highlight .err { color: #a61717; } /* Error */
.highlight .k { color: #000; font-weight: bold; } /* Keyword */
.highlight .o { color: #000; font-weight: bold; } /* Operator */
.highlight .cm { color: #998; font-style: italic; } /* Comment.Multiline */
.highlight .cp { color: #999; font-weight: bold; } /* Comment.Preproc */
.highlight .c1 { color: #998; font-style: italic; } /* Comment.Single */
.highlight .cs { color: #999; font-weight: bold; font-style: italic; } /* Comment.Special */
.highlight .gd { color: #000; background-color: #fdd; } /* Generic.Deleted */
.highlight .gd .x { color: #000; background-color: #faa; } /* Generic.Deleted.Specific */
.highlight .ge { font-style: italic; } /* Generic.Emph */
.highlight .gr { color: #a00; } /* Generic.Error */
.highlight .gh { color: #999; } /* Generic.Heading */
.highlight .gi { color: #000; background-color: #dfd; } /* Generic.Inserted */
.highlight .gi .x { color: #000; background-color: #afa; } /* Generic.Inserted.Specific */
.highlight .go { color: #888; } /* Generic.Output */
.highlight .gp { color: #555; } /* Generic.Prompt */
.highlight .gs { font-weight: bold; } /* Generic.Strong */
.highlight .gu { color: #aaa; } /* Generic.Subheading */
.highlight .gt { color: #a00; } /* Generic.Traceback */
.highlight .kc { color: #000; font-weight: bold; } /* Keyword.Constant */
.highlight .kd { color: #000; font-weight: bold; } /* Keyword.Declaration */
.highlight .kp { color: #000; font-weight: bold; } /* Keyword.Pseudo */
.highlight .kr { color: #000; font-weight: bold; } /* Keyword.Reserved */
.highlight .kt { color: #458; font-weight: bold; } /* Keyword.Type */
.highlight .m { color: #099; } /* Literal.Number */
.highlight .s { color: #d14; } /* Literal.String */
.highlight .na { color: #008080; } /* Name.Attribute */
.highlight .nb { color: #0086B3; } /* Name.Builtin */
.highlight .nc { color: #458; font-weight: bold; } /* Name.Class */
.highlight .no { color: #008080; } /* Name.Constant */
.highlight .ni { color: #800080; } /* Name.Entity */
.highlight .ne { color: #900; font-weight: bold; } /* Name.Exception */
.highlight .nf { color: #900; font-weight: bold; } /* Name.Function */
.highlight .nn { color: #555; } /* Name.Namespace */
.highlight .nt { color: #000080; } /* Name.Tag */
.highlight .nv { color: #008080; } /* Name.Variable */
.highlight .ow { color: #000; font-weight: bold; } /* Operator.Word */
.highlight .w { color: #bbb; } /* Text.Whitespace */
.highlight .mf { color: #099; } /* Literal.Number.Float */
.highlight .mh { color: #099; } /* Literal.Number.Hex */
.highlight .mi { color: #099; } /* Literal.Number.Integer */
.highlight .mo { color: #099; } /* Literal.Number.Oct */
.highlight .sb { color: #d14; } /* Literal.String.Backtick */
.highlight .sc { color: #d14; } /* Literal.String.Char */
.highlight .sd { color: #d14; } /* Literal.String.Doc */
.highlight .s2 { color: #d14; } /* Literal.String.Double */
.highlight .se { color: #d14; } /* Literal.String.Escape */
.highlight .sh { color: #d14; } /* Literal.String.Heredoc */
.highlight .si { color: #d14; } /* Literal.String.Interpol */
.highlight .sx { color: #d14; } /* Literal.String.Other */
.highlight .sr { color: #009926; } /* Literal.String.Regex */
.highlight .s1 { color: #d14; } /* Literal.String.Single */
.highlight .ss { color: #990073; } /* Literal.String.Symbol */
.highlight .bp { color: #999; } /* Name.Builtin.Pseudo */
.highlight .vc { color: #008080; } /* Name.Variable.Class */
.highlight .vg { color: #008080; } /* Name.Variable.Global */
.highlight .vi { color: #008080; } /* Name.Variable.Instance */
.highlight .il { color: #099; } /* Literal.Number.Integer.Long */
EOL

# Install required gems
cat > Gemfile <<EOL
source "https://rubygems.org"

gem "jekyll", "~> 4.3.2"
gem "minimal-mistakes-jekyll"
gem "webrick", "~> 1.8"
gem "nokogiri"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
  gem "jekyll-include-cache"
  gem "jekyll-paginate"
  gem "jekyll-sitemap"
  gem "jekyll-gist"
end
EOL

# Install dependencies
bundle install

# Create _config.yml with blog information and custom settings
python3 /app/migration/extract_blog_info.py "${BLOG_XML}" > ${JEKYLL_SITE}/_config.yml.base

# Add custom settings to _config.yml
cat > ${JEKYLL_SITE}/_config.yml <<EOL
# Base settings from Blogger
$(cat ${JEKYLL_SITE}/_config.yml.base)

# Theme settings
minimal_mistakes_skin: "default"

# Site settings
locale: "en-US"
search: true

# Outputting
permalink: /:year/:month/:day/:title/
paginate: 10
paginate_path: /page:num/

# Wider content area
defaults:
  # _posts
  - scope:
      path: ""
      type: posts
    values:
      layout: single
      author_profile: true
      read_time: false
      show_date: true
      comments: false
      share: true
      related: true
      classes: wide

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
EOL

rm ${JEKYLL_SITE}/_config.yml.base

# Create a simple index page
cat > ${JEKYLL_SITE}/index.html <<EOL
---
layout: home
author_profile: true
classes: wide
entries_layout: list
---
EOL

# Create a custom home layout
mkdir -p ${JEKYLL_SITE}/_layouts
cat > ${JEKYLL_SITE}/_layouts/home.html <<EOL
---
layout: archive
---

{{ content }}

<h3 class="archive__subtitle">{{ site.data.ui-text[site.locale].recent_posts | default: "Recent Posts" }}</h3>

{% if paginator %}
  {% assign posts = paginator.posts %}
{% else %}
  {% assign posts = site.posts | sort: 'date' | reverse %}
{% endif %}

{% assign entries_layout = page.entries_layout | default: 'list' %}
<div class="entries-{{ entries_layout }}">
  {% for post in posts %}
    <article class="archive__item">
      <h2 class="archive__item-title no_toc" itemprop="headline">
        <a href="{{ post.url | relative_url }}" rel="permalink">{{ post.title }}</a>
      </h2>
      {% if post.date %}
        <p class="page__meta"><i class="far fa-calendar-alt" aria-hidden="true"></i> {{ post.date | date: "%B %d, %Y" }}</p>
      {% endif %}
      <div class="archive__item-excerpt" itemprop="description">
        {{ post.content | markdownify }}
      </div>
    </article>
  {% endfor %}
</div>

{% include paginator.html %}
EOL

# Convert Blogger posts to Jekyll format
echo "Converting Blogger posts to Jekyll format..."
python3 /app/migration/convert_posts.py "${BLOG_XML}" "${POSTS_DIR}" "${IMAGES_DIR}"

# Organize posts by year and month
echo "Organizing posts by year and month..."
python3 /app/migration/organize_posts.py "${POSTS_DIR}"

# Convert HTML in markdown files to pure markdown
echo "Converting HTML in markdown files to pure markdown..."
python3 /app/migration/html_to_markdown.py "${POSTS_DIR}"

# Clean up any existing _site directory before building
echo "Cleaning up any existing _site directory..."
if [ -d "_site" ]; then
  rm -rf "_site"
fi

# Clean up any HTML files that might still be in the posts directory
echo "Cleaning up any HTML files that might still be in the posts directory..."
find ${POSTS_DIR} -name "*.html" -type f -delete

# Build the Jekyll site
echo "Building Jekyll site..."
JEKYLL_ENV=production bundle exec jekyll build

echo "Jekyll site created successfully at ${JEKYLL_SITE}!" 