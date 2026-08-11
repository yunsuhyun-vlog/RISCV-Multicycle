# RISC-V 32-bit Multicycle CPU with APB SoC

이 프로젝트는 Vivado 환경에서 SystemVerilog 및 Verilog를 사용하여 **RV32I (RISC-V 32-bit Integer)** 아키텍처 기반의 **멀티 사이클(Multi-cycle) 프로세서**와 **APB(Advanced Peripheral Bus)**를 결합해 설계한 팀 프로젝트입니다.

## 🎯 수행 목표 및 담당 역할
- **수행 기간**: 2026-03-20 ~ 2026-03-30
- **수행 목표**: RISC-V Multi Cycle CPU를 중심으로 BUS와 주변 장치 연동 설계
- **담당 역할 (팀 프로젝트)**: Multi-Cycle CPU 및 APB Bus Protocol 설계
- **사용 기술**: APB Protocol, Memory Map IO(MMIO), Timing 및 Power Report 분석

---

## 🏗️ 전체 아키텍처 및 통신 규격 (Overall Architecture)

### 1. APB Protocol (Advanced Peripheral Bus)
- `IDLE` ➔ `SETUP` ➔ `ACCESS` 흐름으로 상태가 천이됩니다.
- 1개의 채널에서 Read/Write를 효율적으로 수행하여 주변 장치와 프로세서 간의 데이터를 교환합니다.

### 2. MMIO (Memory Mapped I/O)
- 주변장치(UART, FND, GPIO, GPI, GPO, RAM, ROM 등)를 **메모리와 동일한 주소 공간에 맵핑(Mapping)** 하였습니다.
- 이를 통해 별도의 전용 I/O 명령어 없이, RISC-V의 기본 `load`/`store` 명령어만으로도 모든 주변 장치를 통합 제어할 수 있습니다.

<img width="500" height="300" alt="image" src="https://github.com/user-attachments/assets/90c8e1d8-c58e-4d0c-92df-b4098ae5c67a" />


---

## ⚙️ Multi-Cycle 프로세서 설계 (Instruction Execution Stage)

명령어 처리를 여러 사이클로 분할하여 수행하며, 각 명령어의 특성에 따라 불필요한 대기 시간을 획기적으로 감소시켰습니다.

1. **Fetch**: 명령어 인출
2. **Decode**: 제어 신호 해독 및 레지스터 읽기
3. **Execute**: ALU 산술/논리 연산 및 데이터/분기 주소 계산
4. **Mem (Memory)**: 데이터 메모리 접근 (Load/Store)
5. **Write Back**: 연산 결과나 메모리에서 읽어온 데이터를 레지스터에 저장
<img width="500" height="300" alt="image" src="https://github.com/user-attachments/assets/712624be-de75-4f21-b036-0cf4fe8af15f" />


---

## 📊 최적화 결과 분석 (Implementation: Single-cycle vs Multi-cycle)

초기 Single-cycle 설계의 문제점을 파악하고, Multi-cycle FSM을 도입하여 **Timing(타이밍)**과 **Power(전력 소모)** 측면에서 대폭 개선을 이루어냈습니다.

### 1. Timing 분석 (Negative Slack 해결)
- **Single-cycle의 문제점 (Setup Violation)**
  - WNS(Worst Negative Slack): **-0.092 ns** / TNS: -0.282 ns
  - **이슈**: 과도한 Logic Depth 및 Fan-out으로 인한 타이밍 위반
  - **해결 방안**: Critical Path를 추적하고, 명령어 처리 단계를 분할해 레지스터를 삽입(Multi-cycle 설계)
- **Multi-cycle 개선 결과**
  - WNS: **0.256 ns** / TNS: **0.000 ns** ➔ Setup Timing 완벽 충족

### 2. Power 소모 감소 분석
| 측정 항목 | Single-cycle | Multi-cycle (개선 후) |
|---|---|---|
| **Total Power** | 0.142 W | **0.095 W** |
| **Dynamic Power** | 0.072 W | **0.023 W** |
<img width="500" height="300" alt="image" src="https://github.com/user-attachments/assets/0b1e25ec-1aa5-4690-9dfe-44a07b3c615b" />

- **분석 결과**: Multi-cycle FSM 도입을 통해 명령어 처리 단계를 분할함으로써, 불필요한 회로의 동작이 줄어들어 **전체적인 Switching Power(Dynamic Power)가 급감**하는 효과를 달성했습니다.

---

## 📂 폴더 구조 (Project Structure)
소스 코드는 `0330_reg_add_multicycle.srcs/sources_1/` 디렉토리 내에 위치하고 있습니다.
- `RV32I_top.sv`: 최상위 SoC 모듈 (CPU 코어 및 APB 버스 시스템 통합)
- `RV32I_CPU.sv`, `RV32I_datapath.sv`: RISC-V 멀티 사이클 제어 장치 및 데이터 패스
- `instruction_mem.sv`: 명령어 메모리 (ROM)
- `APB_Master.sv`, `APB_Slave.sv`: AMBA APB 통신 인터페이스 모듈
- `UART.sv`, `fnd.v`: 주변 장치(Peripheral) 제어 로직

## 깃허브 업로드 관리
본 레포지토리는 소스 코드 위주로 깔끔하게 관리하기 위해 `.gitignore`가 설정되어 있습니다. (Vivado의 찌꺼기 파일인 `.cache`, `.sim`, `.runs` 등은 모두 자동 제외됩니다.)
