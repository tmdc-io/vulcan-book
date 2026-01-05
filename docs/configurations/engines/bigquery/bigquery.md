# BigQuery

Google BigQuery is a serverless, highly scalable data warehouse that enables super-fast SQL queries using the processing power of Google's infrastructure. It's ideal for large-scale analytics, machine learning workloads, and real-time data analysis. Vulcan integrates seamlessly with BigQuery to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `bigquery`

### Prerequisites

1. A Google Cloud Platform (GCP) project with BigQuery enabled
2. A service account with appropriate permissions (or OAuth credentials)
3. A service account key file (JSON format) for authentication

### Permissions

Vulcan requires the following BigQuery permissions:

- `bigquery.datasets.create` - to create datasets (schemas)
- `bigquery.tables.create` - to create tables and views
- `bigquery.tables.getData` - to read data from tables
- `bigquery.tables.updateData` - to insert, update, and delete data
- `bigquery.jobs.create` - to run queries

The `BigQuery Data Editor` and `BigQuery Job User` roles provide these permissions.

### Connection Options

Here are all the connection parameters you can use when setting up a BigQuery gateway:

| Option    | Description                                                                                | Type   | Required |
|-----------|--------------------------------------------------------------------------------------------|:------:|:--------:|
| `type`    | Engine type name - must be `bigquery`                                                      | string | Y        |
| `method`  | Authentication method (`service-account`, `oauth`, `oauth-secrets`, `application-default`) | string | Y        |
| `project` | The GCP project ID where BigQuery resources are located                                    | string | Y        |
| `keyfile` | Path to the service account JSON key file (required for `service-account` method)          | string | N        |

### Service Account Key File

The `keyfile` is a JSON key file downloaded from the Google Cloud Console:

1. Go to **IAM & Admin → Service Accounts**
2. Select your service account (or create a new one)
3. Go to the **Keys** tab
4. Click **Add Key → Create new key**
5. Select **JSON** and click **Create**

The downloaded file will have the following structure:

```json
{
  "type": "service_account",
  "project_id": "<your-project-id>",
  "private_key_id": "<key-id>",
  "private_key": "-----BEGIN PRIVATE KEY-----\n<private-key-content>\n-----END PRIVATE KEY-----\n",
  "client_email": "<service-account-name>@<project-id>.iam.gserviceaccount.com",
  "client_id": "<client-id>",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/<service-account-name>",
  "universe_domain": "googleapis.com"
}
```

!!! note
    The `BigQuery Data Editor` and `BigQuery Job User` roles together provide the minimum permissions required for Vulcan to operate.

!!! warning
    Never commit your keyfile to version control. Add it to `.gitignore` and store it securely.
