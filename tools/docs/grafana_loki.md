# Log Monitoring System Configuration Summary (Loki + Promtail + Grafana)

## 1. Loki
- **Version**: Loki 3.0.0
- **Storage Configuration (`schema_config`)**:
    - **Schema**: `v11` (or updated as necessary)
    - **Index Type**: `boltdb-shipper` (or `tsdb` if updated for structured metadata support)
    - **Storage Path**: `/loki/chunks`
- **Limitations (`limits_config`)**:
    - `allow_structured_metadata: false` — temporarily disables structured metadata to work with `v11` schema.
    - `reject_old_samples: false` — allows logs regardless of timestamp age.
    - `max_streams_per_user: 10000` — max log streams per user.
    - `max_line_size: 2048` — max line size for logs.
    - `volume_enabled: true` — enables log volume metrics collection.
- **API Endpoints for Log Volume Analysis**:
    - `/loki/api/v1/index/volume` — current log volume.
    - `/loki/api/v1/index/volume_range` — log volume over a specified time range.

## 2. Promtail
- **Version**: Promtail 3.1.2
- **Log Shipping Configuration**:
    - Promtail is set to collect logs from Docker containers via Docker API.
    - The primary log path for Promtail is `/var/lib/docker/containers`.
- **Key Settings**:
    - Collects logs based on the `{job="docker"}` label, capturing all Docker containers by default.
    - Automatically detects and transfers labels (e.g., `container_name` and `job`).
- **Error Handling**:
    - Configured to overwrite excessively old timestamps for compatibility with Loki.

## 3. Grafana
- **Log Dashboard**:
    - Grafana is configured to work with Loki as a data source.
    - To visualize logs, create a new dashboard in Grafana, select a visualization type, and set up LogQL queries as needed.
- **Access Configuration**:
    - Grafana is accessible at `http://logs.<your_domain>` (or as specified in `VIRTUAL_HOST`).
    - **Default Login**: `admin`
    - **Default Password**: `admin`

## Sample Queries in Grafana
- **Query for all logs from `nginx-proxy` container**:
  ```logql
  {container_name="nginx-proxy"}
  ```
- **Query to filter logs containing errors**:
  ```logql
  {job="docker"} |= "error"
  ```

## Useful Commands for Managing Containers
- **Restart containers**:
  ```bash
  docker-compose down && docker-compose up -d --build
  ```
- **View Loki logs**:
  ```bash
  docker-compose logs loki
  ```

## Current Storage Folders and Volumes
- **Grafana Data**: `./data/grafana:/var/lib/grafana`
- **Loki Data**: `./loki/data:/loki`
- **Promtail Data**: `/var/lib/docker/containers`