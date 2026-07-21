# RISC-V 32-bit Multicycle CPU with APB SoC

이 프로젝트는 Vivado 환경에서 SystemVerilog 및 Verilog를 사용하여 구현한 **RV32I (RISC-V 32-bit Integer)** 아키텍처 기반의 멀티 사이클(Multicycle) 프로세서와 **APB(Advanced Peripheral Bus)** 서브시스템이 통합된 **SoC (System on Chip)** 설계입니다.

## 주요 기능 및 특징 (Features)
- **RV32I 아키텍처 완벽 지원**: 데이터 처리(ALU), 메모리 접근(Load/Store), 분기(Branch) 및 점프(Jump) 등 RISC-V 32비트 기본 명령어 셋 지원
- **멀티 사이클 (Multicycle) 동작**: 명령어를 여러 단계로 나누어 처리함으로써 데이터 패스의 하드웨어 자원을 효율적으로 공유하고 동작을 안정화
- **APB (Advanced Peripheral Bus) 버스 아키텍처 도입**:
  - `APB_Master`: CPU 코어와 다양한 주변 장치(Peripherals)를 연결하는 버스 마스터
  - **Memory-Mapped I/O 기반의 APB Slave 모듈**:
    - `APB_RAM`: 메인 데이터 메모리 (RAM)
    - `APB_GPI`, `APB_GPO`: 단방향 범용 입출력(스위치 입력 및 LED 출력 제어 등)
    - `APB_GPIO`: 양방향 범용 입출력 핀
    - `APB_FND`: 7-Segment(FND) 디스플레이 제어기
    - `APB_UART`: UART 시리얼 통신 제어기 (PC 등 외부 기기와의 통신)
- **Basys-3 FPGA 보드 호환**: 하드웨어 검증을 위한 핀 매핑 제약 조건 포함 (`Basys-3-Master.xdc`)

## 프로젝트 구조
소스 코드는 `0330_reg_add_multicycle.srcs/sources_1/` 디렉토리 내에 체계적으로 위치하고 있습니다.
- `RV32I_top.sv`: 최상위 SoC 모듈 (CPU 코어와 APB 버스 시스템 결합)
- `RV32I_CPU.sv`, `RV32I_datapath.sv`: RISC-V 멀티 사이클 제어부 및 데이터 패스
- `instruction_mem.sv`: 명령어 메모리
- `APB_Master.sv`, `APB_Slave.sv`: AMBA APB 버스 표준 인터페이스
- `UART.sv`, `fnd.v`: 주변 장치(Peripheral) 하위 제어 모듈
- `tb.sv` (sim_1 디렉토리): 통합 기능 검증용 테스트벤치

## 깃허브 업로드 관리
이 레포지토리는 소스 코드 위주로 깔끔하게 관리하기 위해 `.gitignore`가 설정되어 있습니다. (Vivado의 `.cache`, `.sim`, `.runs` 등의 빌드 임시 파일은 제외됨)
