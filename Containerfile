# Dockerfile for Claude Skills MCP Backend
# Optimized for production deployment with CPU-only PyTorch

FROM registry.access.redhat.com/ubi8/python-312:latest
RUN pwd
USER 1001
# Install uv
RUN pip install --no-cache-dir uv

# Set working directory
WORKDIR /opt/app-root/src

RUN mkdir -p /opt/app-root/src/local_skills

COPY local-skills /opt/app-root/src/local_skills

RUN ls -altr & pwd

# Copy backend source
COPY ./packages/backend/ /opt/app-root/src/
COPY config-container.json /opt/app-root/src/



RUN ls -altr & pwd
# Install backend package
RUN cd /opt/app-root/src/ && uv pip install .

# Expose default port
EXPOSE 8765

# Run backend server
# Default: local access (127.0.0.1)
# For remote access, override with: --host 0.0.0.0
ENTRYPOINT ["claude-skills-mcp-backend"]
CMD ["--host", "0.0.0.0", "--port", "8765", "--config", "config-container.json"] 

