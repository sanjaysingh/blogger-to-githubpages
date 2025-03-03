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

# Copy all necessary files
COPY sample-blog.xml /app/
COPY *.py /app/
COPY *.sh /app/
COPY main.css /app/

# Set permissions
RUN chmod +x /app/*.sh

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"] 