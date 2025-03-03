FROM ruby:3.1-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    npm \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-bs4 \
    python3-markdown \
    && rm -rf /var/lib/apt/lists/*

# Verify Python packages are installed
RUN python3 -c "import bs4; import markdown; print('Python packages verified')"

# Install Jekyll and Bundler
RUN gem install jekyll bundler

# Set up working directory
WORKDIR /app

# Copy migration scripts and blog XML
COPY sample-blog.xml /app/
COPY ./ /app/migration/

# Set permissions
RUN chmod +x /app/migration/*.sh

# Set entrypoint
ENTRYPOINT ["/app/migration/entrypoint.sh"] 