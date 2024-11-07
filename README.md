# 🌐 Cloud DDoS Detection & Prevention with Machine Learning

## 📜 Project Overview
This project focuses on developing a cloud-based DDoS (Distributed Denial of Service) prevention system using Machine Learning (ML) and Deep Learning (DL) models. The solution aims to detect and mitigate DDoS attacks in real-time, with the ability to learn and adapt to new attack patterns as they emerge.

## ✨ Features
- ⚡ **Real-time DDoS Detection:** Monitors cloud traffic and identifies malicious activities.
- 🧠 **Adaptive Learning:** Uses Incremental Learning Models (ILMs) to continuously learn and improve its defense mechanisms against new attack patterns.
- 🔄 **Hybrid ML/DL Architecture:** Combines traditional ML for known attack types with ILM for novel, zero-day attacks.
- 🕵️‍♂️ **Honeypot Integration:** Optionally incorporates honeypots for deep analysis of suspicious traffic.
- 🔍 **Anomaly Detection:** Detects abnormal traffic patterns using anomaly detection techniques.

## 🏗️ Architecture
1. **Data Collection & Preprocessing**: Traffic logs are continuously collected and processed for feature extraction.
2. **Modeling**: A hybrid of traditional supervised learning and Incremental Learning is used to identify known and new DDoS attacks.
3. **Real-Time Decision Making**: The system employs online learning models to adapt to new traffic patterns in real-time.
4. **Feedback Loop**: Detected attacks are labeled and used to retrain the model, ensuring the system keeps evolving.




## ⚙️ Setup & Installation
1. Clone the Repository 
    ```bash
    git clone https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud.git
    cd Minor-Project-DDoS-on-Cloud
    ```

2. Run Setup: Ensure you have Python 3.11 or 3.12 installed, then open powershell and run:
    ```bash
    .\setup.sh
    ```


<!-- ## 🚀 Usage
1. Preprocess Data: To preprocess traffic data:
```bash
python src/preprocessing/preprocess.py
```

1. Train the Model: To train the ML/DL model for DDoS detection:
```bash
python src/models/train_model.py
```

1. Run Real-time Detection: For real-time DDoS detection using streaming data:
```bash
python src/models/run_realtime_detection.py
```
1. Analyze Results: You can view the logs and performance metrics in the `results` folder. -->


## 🔮 Future Enhancements
- ☁️ Cloud Auto-scaling: Implement an automated cloud scaling mechanism based on detected traffic loads.
- 🕸️ Advanced Honeypots: Use more sophisticated honeypots for detailed analysis of attackers' behavior.
## 🤝 Contributors ✨

Thanks goes to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://deepesh-patil.vercel.app/"><img src="https://avatars.githubusercontent.com/u/123585104?v=4?s=100" width="100px;" alt="Deepesh Patil"/><br /><sub><b>Deepesh Patil</b></sub></a><br /><a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=deepesh611" title="Code">💻</a> <a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=deepesh611" title="Documentation">📖</a> <a href="#research-deepesh611" title="Research">🔬</a> <a href="#ideas-deepesh611" title="Ideas, Planning, & Feedback">🤔</a> <a href="#content-deepesh611" title="Content">🖋</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Sakshamdharmik"><img src="https://avatars.githubusercontent.com/u/123961289?v=4?s=100" width="100px;" alt="Sakshamdharmik"/><br /><sub><b>Sakshamdharmik</b></sub></a><br /><a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=Sakshamdharmik" title="Code">💻</a> <a href="#research-Sakshamdharmik" title="Research">🔬</a> <a href="#content-Sakshamdharmik" title="Content">🖋</a> <a href="#ideas-Sakshamdharmik" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Codeguruu03"><img src="https://avatars.githubusercontent.com/u/123642608?v=4?s=100" width="100px;" alt="Naman Goyal"/><br /><sub><b>Naman Goyal</b></sub></a><br /><a href="#content-Codeguruu03" title="Content">🖋</a> <a href="#ideas-Codeguruu03" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=Codeguruu03" title="Documentation">📖</a> <a href="#research-Codeguruu03" title="Research">🔬</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/imcoder44"><img src="https://avatars.githubusercontent.com/u/157146424?v=4?s=100" width="100px;" alt="imcoder44"/><br /><sub><b>imcoder44</b></sub></a><br /><a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=imcoder44" title="Documentation">📖</a> <a href="https://github.com/deepesh611/Minor-Project-DDoS-on-Cloud/commits?author=imcoder44" title="Code">💻</a> <a href="#content-imcoder44" title="Content">🖋</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
