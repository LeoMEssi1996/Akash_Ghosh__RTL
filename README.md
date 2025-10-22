This repository is part of the Advanced RTL Design & Verification coursework, completed by Akash Ghosh.
It focuses on UART (Universal Asynchronous Receiver/Transmitter) interfacing with an AXI4-Stream bus, exploring the full cycle from design → bug insertion → debugging → correction → verification.

This project demonstrates:

Creation of intentional functional bugs in a UART–AXI interface.

Step-by-step debugging and correction of multi-level logical errors.

Development of specification documents, error testbenches, and corrected verification benches.

Verification at both RTL and behavioral abstraction levels

Akash_Ghosh_RTL_Home_Work_Solution/
│
├── Design Specification Document/
│   ├── Spec-Doc/
│   │   ├── AXI4_Stream_UART_Design_Spec.docx
│   │   └── UART_AXI_Debug_Fix_Spec.docx
│
├── Error/
│   ├── RTL/
│   │   ├── Error_01.v
│   │   ├── Error_2.v
│   │   ├── Error_3.v
│   │   ├── Error_4.v
│   │   └── Error_5.v
│   │
│   └── Test Bench/
│       ├── tb_error1_tx.v
│       ├── tb_error2_tx.v
│       ├── tb_error3_tx.v
│       ├── tb_error4_tx.v
│       └── tb_error5_rx.v
│
├── Solution/
│   ├── Correct_RTL/
│   │   ├── uart_tx_corr_1.v
│   │   ├── uart_tx_corr_2.v
│   │   ├── uart_tx_corr_3.v
│   │   ├── uart_tx_corr_4.v
│   │   └── uart_rx_corr_5.v
│   │
│   └── Correct_Test-Bench/
│       ├── tb_corr1_tx.v
│       ├── tb_corr2_tx.v
│       ├── tb_corr3_tx.v
│       ├── tb_corr4_tx.v
│       └── tb_corr5_rx.v
│
└── Ilm_challenge/
    ├── Problem-1.docx
    └── Problem-2.docx
