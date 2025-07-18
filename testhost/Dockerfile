# -------- Stage 1: Builder --------
FROM python:3.14.0b4-slim AS builder

ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        jq \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        gcc \
        iputils-ping \
        build-essential \
        python-dev-is-python3 && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install "setuptools<67" && \
    pip install --no-cache-dir -r requirements.txt

RUN git clone --depth 1 https://github.com/vmummer/web-scraper.git /home/web-scraper && \
    rm -rf /home/web-scraper/.git && \
    git clone --depth 1 https://github.com/vmummer/juice-shop-solver.git /home/juice-shop-solver && \
    rm -rf /home/juice-shop-solver/.git

# -------- Stage 2: Final Image --------
FROM python:3.14.0b4-slim

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=builder $VIRTUAL_ENV $VIRTUAL_ENV
COPY --from=builder /home/web-scraper /home/web-scraper
COPY --from=builder /home/juice-shop-solver /home/juice-shop-solver

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        jq \
        libxml2 \
        libxslt1-dev \
        iputils-ping \
        # ca-certificates and curl might be needed if your app makes https requests at runtime
        ca-certificates \
        curl \
        sqlmap && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*


# Copy local files
COPY cp /home/

WORKDIR /home/cp


CMD ["python"]

