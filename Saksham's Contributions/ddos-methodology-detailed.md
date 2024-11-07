# 2.2. Methodology of the Work

## DDoS Detection System

The proposed DDoS (Distributed Denial of Service) detection system employs a hybrid approach combining traditional machine learning, deep learning, and incremental learning techniques. The system's architecture is designed to provide real-time detection capabilities while continuously adapting to new attack patterns.

### 2.2.1 Data Collection and Feature Engineering

The system processes network traffic data characterized by the following key features:
```
- pktcount: Packet count metrics
- bytecount: Byte count statistics
- flows: Network flow information
- pktrate: Packet rate measurements
- byteperflow: Bytes per flow ratio
- tx_kbps: Transmission rate in kilobytes per second
- rx_kbps: Reception rate in kilobytes per second
- tot_kbps: Total throughput in kilobytes per second
```

Data preprocessing involves several crucial steps:
1. Categorical encoding using LabelEncoder for:
   - Protocol information
   - Source addresses (src)
   - Destination addresses (dst)
   - Switch identifiers

2. Feature normalization using StandardScaler:
```python
X_scaled = self.scaler.fit_transform(np.nan_to_num(X, nan=0.0))
```

### 2.2.2 Model Architecture

The system implements a three-tier architecture:

#### 1. Deep Learning Model (DDoSDetector)
```python
class DDoSDetector(nn.Module):
    def __init__(self, input_dim):
        super(DDoSDetector, self).__init__()
        self.layer1 = nn.Linear(input_dim, 64)
        self.layer2 = nn.Linear(64, 32)
        self.layer3 = nn.Linear(32, 16)
        self.layer4 = nn.Linear(16, 2)
```
- Four-layer neural network with decreasing neuron counts
- Batch normalization for training stability
- ReLU activation functions
- Dropout (0.3) for regularization

#### 2. Random Forest Classifier
```python
self.rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    min_samples_split=5,
    min_samples_leaf=2,
    n_jobs=-1,
    random_state=42
)
```
- Ensemble of 100 decision trees
- Maximum depth of 10 for preventing overfitting
- Optimized leaf and split parameters

#### 3. Incremental Random Forest
```python
class IncrementalRandomForest:
    def __init__(self, n_estimators=10):
        self.model = RandomForestClassifier(
            n_estimators=n_estimators, 
            warm_start=True
        )
```
- Supports continuous learning
- Warm start capability for model updates
- Dynamic estimator adjustment

### 2.2.3 Training Methodology

The training process follows a multi-phase approach:

1. Initial Training Phase
```python
def train_initial_model(self, X, y):
    X_scaled = self.scaler.fit_transform(np.nan_to_num(X, nan=0.0))
    
    # Train Random Forest
    self.rf_model.fit(X_scaled, y)
    
    # Train Deep Learning model
    self.dl_model = DDoSDetector(input_dim)
    dataset = DDoSDataset(X_scaled, y)
    train_loader = DataLoader(dataset, batch_size=self.batch_size, shuffle=True)
```

2. Incremental Learning Phase
```python
def update_model(self, X, y):
    X_scaled = self.scaler.transform(np.nan_to_num(X, nan=0.0))
    self.incremental_model.partial_fit(X_scaled, y)
```

### 2.2.4 Ensemble Integration

The system combines predictions from all three models using weighted averaging:
```python
def predict(self, X):
    X_scaled = self.scaler.transform(np.nan_to_num(X, nan=0.0))
    
    # Get predictions from each model
    rf_pred = self.rf_model.predict_proba(X_scaled)
    dl_pred = torch.softmax(self.dl_model(torch.FloatTensor(X_scaled)), dim=1).numpy()
    incr_pred = self.incremental_model.predict_proba(X_scaled)
    
    # Ensemble predictions
    ensemble_pred = (rf_pred + dl_pred + incr_pred) / 3
```

### 2.2.5 Performance Metrics and Monitoring

The system continuously monitors several key metrics:

1. Accuracy Metrics
```python
metrics = {
    'rf_accuracy': accuracy_score(y, rf_pred),
    'dl_accuracy': accuracy_score(y, dl_pred),
    'incremental_accuracy': accuracy_score(y, incr_pred),
    'ensemble_accuracy': accuracy_score(y, ensemble_pred)
}
```

2. False Positive Rate Analysis
```python
def get_fpr(cm):
    tn, fp, fn, tp = cm.ravel()
    return fp / (fp + tn) if (fp + tn) > 0 else 0
```

### 2.2.6 Data Visualization and Analysis

The system implements comprehensive visualization capabilities:

1. Model Performance Tracking
```python
def plot_model_performance(detector):
    metrics_df = pd.DataFrame(detector.metrics_data)
    metrics_df.set_index('update_number')[accuracy_columns].plot()
```

2. Traffic Pattern Analysis
```python
def plot_meaningful_visualizations(df):
    # Packet Rate Analysis
    sns.boxplot(x='label', y='pktrate', data=df)
    
    # Flow Distribution
    sns.kdeplot(x='flows', hue='label', data=df, fill=True)
```

### 2.2.7 System Optimization

The system incorporates several optimization techniques:

1. Batch Processing
```python
chunk_size = 1000
for i in range(0, len(X_test), chunk_size):
    X_chunk = X_test[i:i+chunk_size]
    y_chunk = y_test[i:i+chunk_size]
```

2. Data Augmentation Using SMOTE
```python
smote = SMOTE()
X_res, y_res = smote.fit_resample(df_improved.drop('label', axis=1), df_improved['label'])
```

This methodology ensures robust DDoS detection while maintaining adaptability to evolving attack patterns through continuous learning and model updates.
