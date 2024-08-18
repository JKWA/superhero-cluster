# Dispatch Cluster

Welcome to the Dispatch Dispatch project! This README will guide you through the setup process and explain how to run various tasks using Visual Studio Code.

## Prerequisites

Before you begin, make sure you have the following software installed on your machine:

- [Visual Studio Code](https://code.visualstudio.com/download)
- [Phoenix Framework](https://hexdocs.pm/phoenix/installation.html)
- [Make](https://sp21.datastructur.es/materials/guides/make-install.html)

## Getting Started

### 1. Clone the Repository

Start by cloning the repository to your local machine:

```sh
git clone https://github.com/JKWA/superhero-cluster.git
cd superhero_cluster
```

### 2. Install Dependencies

Once inside the project directory, install all necessary dependencies for both the `/location` and `/superhero` subdirectories:

```sh
make setup
```

## Tasks Overview

The project includes Visual Studio Code tasks defined in `.vscode/tasks.json`.

### Run Dispatch Cluster

1. Open the command palette in Visual Studio Code by pressing `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS).
2. Type `Run Task` and select it from the list.
3. Choose `Run Dispatch Cluster`.

Running the `Run Superhero Cluster` task generates four local terminals in VS Code: one for each city and one for the dispatch LiveView.

Dispatch runs on [http://localhost:4900](http://localhost:4900)