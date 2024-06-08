locals {
  oidc_config = jsondecode(data.http.oidc_config.response_body)
}

data "http" "oidc_config" {
  url = "${var.oidc_issuer}/.well-known/openid-configuration"

  request_headers = {
    accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "OIDC discovery endpoint response status code invalid"
    }
  }
}
