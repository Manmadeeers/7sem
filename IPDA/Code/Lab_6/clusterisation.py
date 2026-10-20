from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.cluster.hierarchy import dendrogram, linkage
from sklearn.cluster import AgglomerativeClustering, KMeans
from sklearn.metrics import (
    davies_bouldin_score,
    silhouette_samples,
    silhouette_score,
)
from sklearn.preprocessing import MinMaxScaler


def create_feature_matrix(data):
    features = ["Annual Income (k$)", "Spending Score (1-100)"]
    X = data[features].copy()

    print("Research goal: segment customers by income and spending behaviour.")
    print("\nSelected features:")
    print(X.head())

    return X


def preprocess_features(X):
    X = X.apply(pd.to_numeric, errors="raise")
    X = X.replace([np.inf, -np.inf], np.nan)

    print("\nMissing values before preprocessing:")
    print(X.isna().sum())

    if X.isna().all().any():
        raise ValueError("A selected feature contains no valid values.")

    X = X.fillna(X.median())

    print("\nMissing values after preprocessing:")
    print(X.isna().sum())
    print("Categorical encoding is unnecessary: all selected features are numeric.")

    return X


def normalize_features(X):
    scaler = MinMaxScaler()
    X_scaled = pd.DataFrame(
        scaler.fit_transform(X),
        columns=X.columns,
        index=X.index,
    )

    print("\nNormalized feature matrix:")
    print(X_scaled.head())

    return X_scaled


def select_k_with_elbow(X_scaled, max_clusters=10):
    upper_limit = min(max_clusters, len(X_scaled) - 1)
    cluster_counts = np.arange(1, upper_limit + 1)
    inertias = []

    for k in cluster_counts:
        model = KMeans(
            n_clusters=int(k),
            init="k-means++",
            n_init=20,
            random_state=42,
        )
        model.fit(X_scaled)
        inertias.append(model.inertia_)

    inertias = np.array(inertias)

    if inertias[0] == inertias[-1]:
        raise ValueError("The data has insufficient variation for clustering.")

    normalized_k = (cluster_counts - cluster_counts[0]) / (
        cluster_counts[-1] - cluster_counts[0]
    )
    normalized_inertia = (inertias - inertias[-1]) / (inertias[0] - inertias[-1])

    distances = (1 - normalized_k - normalized_inertia) / np.sqrt(2)
    elbow_index = int(np.argmax(distances[1:-1])) + 1
    selected_k = int(cluster_counts[elbow_index])

    plt.figure(figsize=(8, 5))
    plt.plot(cluster_counts, inertias, marker="o")
    plt.scatter(
        selected_k,
        inertias[elbow_index],
        color="red",
        s=120,
        label=f"Estimated elbow: k={selected_k}",
        zorder=3,
    )
    plt.xticks(cluster_counts)
    plt.xlabel("Number of clusters")
    plt.ylabel("Inertia")
    plt.title("K-means: elbow method")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()

    print(f"\nEstimated number of K-means clusters: {selected_k}")

    return selected_k


def perform_kmeans(X_scaled, n_clusters):
    model = KMeans(
        n_clusters=n_clusters,
        init="k-means++",
        n_init=20,
        random_state=42,
    )
    labels = model.fit_predict(X_scaled)

    return labels


def select_k_with_dendrogram(X_scaled, max_clusters=10):
    linkage_matrix = linkage(X_scaled.to_numpy(), method="ward")
    upper_limit = min(max_clusters, len(X_scaled) - 1)
    candidate_counts = np.arange(2, upper_limit + 1)

    gaps = np.array(
        [linkage_matrix[-(k - 1), 2] - linkage_matrix[-k, 2] for k in candidate_counts]
    )

    selected_k = int(candidate_counts[np.argmax(gaps)])
    lower_height = linkage_matrix[-selected_k, 2]
    upper_height = linkage_matrix[-(selected_k - 1), 2]
    cut_height = (lower_height + upper_height) / 2

    plt.figure(figsize=(12, 6))
    dendrogram(
        linkage_matrix,
        no_labels=True,
        color_threshold=cut_height,
        above_threshold_color="gray",
    )
    plt.axhline(
        cut_height,
        color="red",
        linestyle="--",
        label=f"Selected cut: k={selected_k}",
    )
    plt.xlabel("Customers")
    plt.ylabel("Ward linkage distance")
    plt.title("Hierarchical clustering: dendrogram")
    plt.legend()
    plt.tight_layout()

    print(f"Estimated number of hierarchical clusters: {selected_k}")
    print(f"Dendrogram cut height: {cut_height:.4f}")

    return selected_k


def perform_hierarchical_clustering(X_scaled, n_clusters):
    model = AgglomerativeClustering(
        n_clusters=n_clusters,
        linkage="ward",
    )

    return model.fit_predict(X_scaled)


def visualize_clusters(X, labels, method_name, selected_position, object_name):
    fig, ax = plt.subplots(figsize=(9, 6))
    colors = plt.get_cmap("tab10")

    for cluster_id in np.unique(labels):
        members = labels == cluster_id
        ax.scatter(
            X.iloc[members, 0],
            X.iloc[members, 1],
            color=colors(int(cluster_id) % 10),
            s=55,
            alpha=0.8,
            label=f"Cluster {cluster_id + 1}",
        )

    selected = X.iloc[selected_position]
    selected_cluster = int(labels[selected_position]) + 1

    ax.scatter(
        selected.iloc[0],
        selected.iloc[1],
        color="magenta",
        edgecolors="black",
        linewidths=1.5,
        s=260,
        zorder=5,
        label=f"{object_name}: cluster {selected_cluster}",
    )

    ax.annotate(
        object_name,
        (selected.iloc[0], selected.iloc[1]),
        xytext=(10, 12),
        textcoords="offset points",
    )

    ax.set_xlabel(X.columns[0])
    ax.set_ylabel(X.columns[1])
    ax.set_title(f"{method_name}: customer segmentation")
    ax.legend()
    ax.grid(alpha=0.2)
    fig.tight_layout()

    print(f"{method_name}: {object_name} belongs to cluster {selected_cluster}.")


def visualize_silhouettes(sample_scores, labels, average_score, method_name):
    fig, ax = plt.subplots(figsize=(9, 6))
    colors = plt.get_cmap("tab10")
    lower = 10
    tick_positions = []
    tick_labels = []

    for cluster_id in np.unique(labels):
        values = np.sort(sample_scores[labels == cluster_id])
        upper = lower + len(values)

        ax.fill_betweenx(
            np.arange(lower, upper),
            0,
            values,
            color=colors(int(cluster_id) % 10),
            alpha=0.8,
        )

        tick_positions.append((lower + upper) / 2)
        tick_labels.append(str(cluster_id + 1))
        lower = upper + 10

    ax.axvline(
        average_score,
        color="red",
        linestyle="--",
        label=f"Average silhouette: {average_score:.3f}",
    )
    ax.set_yticks(tick_positions)
    ax.set_yticklabels(tick_labels)
    ax.set_xlim(-1, 1)
    ax.set_xlabel("Silhouette coefficient")
    ax.set_ylabel("Cluster")
    ax.set_title(f"{method_name}: silhouette analysis")
    ax.legend()
    fig.tight_layout()


def evaluate_clustering(X_scaled, labels, method_name):
    average_score = silhouette_score(X_scaled, labels)
    db_score = davies_bouldin_score(X_scaled, labels)
    sample_scores = silhouette_samples(X_scaled, labels)

    details = pd.DataFrame(
        {
            "Cluster": labels + 1,
            "Silhouette": sample_scores,
            "Negative": sample_scores < 0,
        }
    )

    summary = details.groupby("Cluster").agg(
        Size=("Silhouette", "size"),
        MeanSilhouette=("Silhouette", "mean"),
        NegativeSilhouettes=("Negative", "sum"),
    )

    print(f"\n{method_name}: per-cluster silhouette analysis")
    print(summary.to_string(float_format=lambda value: f"{value:.4f}"))

    visualize_silhouettes(
        sample_scores,
        labels,
        average_score,
        method_name,
    )

    return {
        "Method": method_name,
        "Clusters": len(np.unique(labels)),
        "Silhouette": average_score,
        "Davies-Bouldin": db_score,
    }


def compare_methods(results):
    comparison = pd.DataFrame(results).set_index("Method")

    print("\nClustering quality comparison:")
    print(comparison.to_string(float_format=lambda value: f"{value:.4f}"))

    silhouette_winner = comparison["Silhouette"].idxmax()
    db_winner = comparison["Davies-Bouldin"].idxmin()

    print("\nHigher silhouette and lower Davies-Bouldin values are better.")

    if np.isclose(
        comparison["Silhouette"].iloc[0],
        comparison["Silhouette"].iloc[1],
    ):
        print("Both methods have approximately equal average silhouettes.")
    elif silhouette_winner == db_winner:
        print(f"{silhouette_winner} performs better according to both metrics.")
    else:
        print(f"{silhouette_winner} has the higher average silhouette.")
        print(f"{db_winner} has the lower Davies-Bouldin index.")
        print(
            f"Using silhouette as the primary criterion, "
            f"the preferred method is {silhouette_winner}."
        )

    print(
        "\nSilhouettes near 1 indicate well-separated objects; "
        "values near 0 indicate overlapping clusters; "
        "negative values indicate possible misassignment."
    )
    print("Cluster numbers are arbitrary and independent between methods.")


def select_object(data, X, position=0):
    if not 0 <= position < len(data):
        raise ValueError("Selected object position is outside the dataset.")

    if "CustomerID" in data.columns:
        object_name = f"Customer {data.iloc[position]['CustomerID']}"
    else:
        object_name = f"Row {position + 1}"

    print(f"\nSelected object: {object_name}")
    print(X.iloc[position].to_string())

    return position, object_name


def main():
    data_path = Path(__file__).resolve().parent / "data.csv"
    data = pd.read_csv(data_path)
    data.columns = data.columns.str.strip()

    X = create_feature_matrix(data)
    X = preprocess_features(X)

    if len(X.drop_duplicates()) < 3:
        raise ValueError("At least three distinct objects are required.")

    X_scaled = normalize_features(X)

    selected_position, object_name = select_object(data, X, position=0)

    max_clusters = min(10, len(X.drop_duplicates()) - 1)

    kmeans_k = select_k_with_elbow(X_scaled, max_clusters)
    kmeans_labels = perform_kmeans(X_scaled, kmeans_k)

    visualize_clusters(
        X,
        kmeans_labels,
        "K-means",
        selected_position,
        object_name,
    )

    hierarchical_k = select_k_with_dendrogram(X_scaled, max_clusters)
    hierarchical_labels = perform_hierarchical_clustering(
        X_scaled,
        hierarchical_k,
    )

    visualize_clusters(
        X,
        hierarchical_labels,
        "Hierarchical clustering",
        selected_position,
        object_name,
    )

    results = [
        evaluate_clustering(X_scaled, kmeans_labels, "K-means"),
        evaluate_clustering(
            X_scaled,
            hierarchical_labels,
            "Hierarchical clustering",
        ),
    ]

    compare_methods(results)
    plt.show()


if __name__ == "__main__":
    main()
