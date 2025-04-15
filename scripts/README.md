# Helm Chart Comparison Script

This script allows you to compare a rendered Helm chart with the latest manifest from a specified GitHub repository. It is particularly useful for keeping your Kubernetes deployments up to date by ensuring that your Helm charts match the latest official manifests.

## Features

- **Generic Usage**: Easily adaptable to any Helm chart and GitHub manifest.
- **Scratch Directory**: Uses a `scratch` directory for temporary files, which is ignored by Git.
- **Simple Comparison**: Provides a unified diff between your Helm chart and the latest manifest.

## Prerequisites

- **Helm**: Ensure Helm is installed and configured.
- **curl**: Used to download the latest manifest from the GitHub repository.
- **diff**: Standard tool for comparing files.

## Usage

### Script Syntax

```bash
./compare_chart.sh <chart_directory> <release_name> <manifest_url>
