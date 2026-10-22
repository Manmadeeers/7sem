from pathlib import Path
from time import perf_counter

import matplotlib.pyplot as plt
import numpy as np
from sklearn.datasets import load_breast_cancer
from sklearn.decomposition import PCA
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC


def evaluate_model(name, model, X_train, X_test, y_train, y_test):
    start = perf_counter()
    model.fit(X_train, y_train)
    training_time = perf_counter() - start

    train_accuracy = accuracy_score(y_train, model.predict(X_train))
    test_accuracy = accuracy_score(y_test, model.predict(X_test))

    print(f"\n{name}")
    print(f"Training accuracy: {train_accuracy:.4f}")
    print(f"Test accuracy: {test_accuracy:.4f}")
    print(f"Training time (full pipeline): {training_time:.6f} seconds")


def main():
    output_dir = Path(__file__).resolve().parent / "pca_results"
    output_dir.mkdir(exist_ok=True)

    data = load_breast_cancer()
    X = data.data
    y = data.target

    print(f"Samples: {X.shape[0]}")
    print(f"Original features: {X.shape[1]}")
    print(f"Missing values: {np.isnan(X).sum()}")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)

    pca_raw = PCA(n_components=2, svd_solver="full")
    pca_scaled = PCA(n_components=2, svd_solver="full")
    X_train_raw_2d = pca_raw.fit_transform(X_train)
    X_train_scaled_2d = pca_scaled.fit_transform(X_train_scaled)

    positions = np.arange(X.shape[1])
    fig, axes = plt.subplots(2, 1, figsize=(17, 10), sharex=True)

    for component, ax in enumerate(axes):
        ax.bar(
            positions - 0.2,
            pca_raw.components_[component],
            width=0.4,
            label="Without scaling",
            color="#c65a36",
        )
        ax.bar(
            positions + 0.2,
            pca_scaled.components_[component],
            width=0.4,
            label="With StandardScaler",
            color="#267b9a",
        )
        ax.axhline(0, color="black", linewidth=0.8)
        ax.set_title(f"Weights of principal component {component + 1}")
        ax.set_ylabel("Component coefficient")
        ax.legend()
        ax.grid(axis="y", alpha=0.25)

    axes[-1].set_xticks(positions)
    axes[-1].set_xticklabels(data.feature_names, rotation=90)
    axes[-1].set_xlabel("Original feature")
    fig.tight_layout()
    fig.savefig(output_dir / "component_weights.png", dpi=160)

    fig, axes = plt.subplots(1, 2, figsize=(13, 5))
    projections = [X_train_raw_2d, X_train_scaled_2d]
    pca_models = [pca_raw, pca_scaled]
    titles = ["PCA without scaling", "PCA with StandardScaler"]

    for ax, projection, pca, title in zip(axes, projections, pca_models, titles):
        for class_id, class_name, color, marker in zip(
            [0, 1], data.target_names, ["#c65a36", "#267b9a"], ["^", "o"]
        ):
            mask = y_train == class_id
            ax.scatter(
                projection[mask, 0],
                projection[mask, 1],
                label=class_name,
                color=color,
                marker=marker,
                s=25,
                alpha=0.65,
            )
        ratios = pca.explained_variance_ratio_ * 100
        ax.set_xlabel(f"PC1 ({ratios[0]:.2f}% of variance)")
        ax.set_ylabel(f"PC2 ({ratios[1]:.2f}% of variance)")
        ax.set_title(title)
        ax.legend()
        ax.grid(alpha=0.25)

    fig.tight_layout()
    fig.savefig(output_dir / "class_distributions.png", dpi=160)

    pca_full = PCA(svd_solver="full")
    pca_full.fit(X_train_scaled)
    cumulative_variance = np.cumsum(pca_full.explained_variance_ratio_)
    n_components = int(np.searchsorted(cumulative_variance, 0.9) + 1)
    retained_variance = cumulative_variance[n_components - 1]

    fig, ax = plt.subplots(figsize=(10, 5))
    counts = np.arange(1, len(cumulative_variance) + 1)
    ax.plot(counts, cumulative_variance * 100, marker="o", color="#267b9a")
    ax.axhline(90, color="#c65a36", linestyle="--", label="90% variance")
    ax.axvline(
        n_components,
        color="#6c559a",
        linestyle="--",
        label=f"Selected: {n_components} components",
    )
    ax.scatter(n_components, retained_variance * 100, color="#c65a36", zorder=3)
    ax.set_xticks(counts)
    ax.set_xlabel("Number of principal components")
    ax.set_ylabel("Cumulative explained variance (%)")
    ax.set_title("Explained variance after StandardScaler")
    ax.legend()
    ax.grid(alpha=0.25)
    fig.tight_layout()
    fig.savefig(output_dir / "explained_variance.png", dpi=160)

    print(f"Training samples: {len(X_train)}")
    print(f"Test samples: {len(X_test)}")
    print(f"Components needed for at least 90% variance: {n_components}")
    print(f"Retained variance: {retained_variance:.2%}")

    svc_without_pca = make_pipeline(
        StandardScaler(), SVC(kernel="rbf", C=1.0, gamma="scale")
    )
    svc_with_pca = make_pipeline(
        StandardScaler(),
        PCA(n_components=n_components, svd_solver="full"),
        SVC(kernel="rbf", C=1.0, gamma="scale"),
    )

    evaluate_model("SVC without PCA", svc_without_pca, X_train, X_test, y_train, y_test)
    evaluate_model("SVC with PCA", svc_with_pca, X_train, X_test, y_train, y_test)

    print(f"\nPlots saved to: {output_dir}")
    plt.show()


if __name__ == "__main__":
    main()
