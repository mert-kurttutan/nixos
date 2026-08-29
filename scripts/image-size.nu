#!/usr/bin/env nu

const ACCEPT = "application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json"

def format-bytes [bytes: int] {
  let units = [B KiB MiB GiB TiB]
  mut value = ($bytes | into float)
  mut unit_index = 0

  while $value >= 1024 and $unit_index < (($units | length) - 1) {
    $value = ($value / 1024)
    $unit_index = ($unit_index + 1)
  }

  if $unit_index == 0 {
    $"($bytes)B"
  } else {
    $"($value | math round --precision 2)($units | get $unit_index)"
  }
}

def platform-name [platform: record] {
  [
    ($platform.os? | default null)
    ($platform.architecture? | default null)
    ($platform.variant? | default null)
    ($platform."os.version"? | default null)
  ] | compact | str join "/"
}

def parse-image [image: string] {
  let image_without_digest = ($image | split row "@" | first)
  let digest = if ($image | str contains "@") {
    $image | split row "@" | get 1
  } else {
    null
  }

  let parts = ($image_without_digest | split row "/")
  let first = ($parts | first)
  let has_registry = (
    ($first | str contains ".")
    or ($first | str contains ":")
    or $first == "localhost"
  )

  let registry = if $has_registry { $first } else { "docker.io" }
  let repo_parts = if $has_registry { $parts | skip 1 } else { $parts }
  let docker_hub_official = (not $has_registry) and (($repo_parts | length) == 1)
  let repo_parts = if $docker_hub_official {
    ["library", ($repo_parts | first)]
  } else {
    $repo_parts
  }

  let last = ($repo_parts | last)
  let has_tag = ($digest == null) and ($last | str contains ":")
  let tag = if $has_tag {
    $last | split row ":" | get 1
  } else if $digest == null {
    "latest"
  } else {
    null
  }

  let repo_parts = if $has_tag {
    ($repo_parts | drop | append ($last | split row ":" | first))
  } else {
    $repo_parts
  }

  {
    registry: $registry
    registry_host: (if $registry == "docker.io" { "registry-1.docker.io" } else { $registry })
    repository: ($repo_parts | str join "/")
    reference: (if $digest == null { $tag } else { $digest })
  }
}

def auth-token [registry: string, repository: string] {
  if $registry == "docker.io" {
    let token = (
      curl -fsSL $"https://auth.docker.io/token?service=registry.docker.io&scope=repository:($repository):pull"
      | from json
      | get token
    )
    return $token
  }

  if $registry == "ghcr.io" {
    let token = (
      curl -fsSL $"https://ghcr.io/token?service=ghcr.io&scope=repository:($repository):pull"
      | from json
      | get token
    )
    return $token
  }

  null
}

def fetch-manifest [image: record, reference: string] {
  let url = $"https://($image.registry_host)/v2/($image.repository)/manifests/($reference)"
  let token = (auth-token $image.registry $image.repository)

  if $token == null {
    curl -fsSL -H $"Accept: ($ACCEPT)" $url | from json
  } else {
    curl -fsSL -H $"Accept: ($ACCEPT)" -H $"Authorization: Bearer ($token)" $url | from json
  }
}

def layer-size [image: record, reference: string] {
  let manifest = (fetch-manifest $image $reference)

  if not ("layers" in ($manifest | columns)) {
    return null
  }

  $manifest.layers | get size | math sum
}

def main [
  image: string
] {
  let parsed = (parse-image $image)
  let manifest = (fetch-manifest $parsed $parsed.reference)

  if "layers" in ($manifest | columns) {
    let size = ($manifest.layers | get size | math sum)

    return [{
      platform: "single"
      bytes: $size
      size: (format-bytes $size)
    }]
  }

  if not ("manifests" in ($manifest | columns)) {
    error make {
      msg: $"No layers or manifest list found for ($image)"
    }
  }

  $manifest.manifests
  | where { |entry|
      ($entry.platform.architecture? | default "") != "unknown"
    }
  | each { |entry|
      let size = (layer-size $parsed $entry.digest)

      {
        platform: (platform-name $entry.platform)
        bytes: $size
        size: (format-bytes $size)
      }
    }
  | sort-by platform
}
