# Dockerfile for Claude Skills MCP Backend
# Optimized for production deployment with CPU-only PyTorch

FROM registry.access.redhat.com/ubi8/python-312:latest
USER 1001

# Install uv
RUN pip install uv

# Set working directory
WORKDIR /opt/app-root/src

# Copy backend source
COPY ./packages/backend/ /opt/app-root/src/

# Install backend package
RUN cd /opt/app-root/src/ && uv pip install .

RUN mkdir -p /opt/app-root/src/local_skills

COPY ./local-skills/ /opt/app-root/src/embed_skills

COPY config-container.json /opt/app-root/src/

ENV CONFIG_FILE=config-container.json

# ENV SENTENCE_TRANSFORMERS_HOME=/tmp/sentence-transformers

# RUN mkdir -p $SENTENCE_TRANSFORMERS_HOME

# Expose default port
EXPOSE 8765

# Run backend server
# Default: local access (127.0.0.1)
# For remote access, override with: --host 0.0.0.0
# ENTRYPOINT ["claude-skills-mcp-backend"]
CMD exec /opt/app-root/bin/claude-skills-mcp-backend --host 0.0.0.0 --port 8765 --verbose --config $CONFIG_FILE