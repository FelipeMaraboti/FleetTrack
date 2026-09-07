# Environment Report - FleetTrack

Este documento descreve o ambiente de desenvolvimento, ferramentas utilizadas e o diagnóstico de integridade da máquina de desenvolvimento para o projeto **FleetTrack**.

---

## 1. Informações do Ambiente

* **Sistema Operacional:** Windows 10 / 11 Pro (64-bit)
* **Dart SDK:** Dart 3.x (Integrado ao Flutter SDK / Standalone)
* **Flutter SDK:** Canal Stable (3.x ou superior)
* **Ambiente de Desenvolvimento (IDE):** Visual Studio Code / Android Studio
* **Extensões Utilizadas:** Dart Code, Flutter Extension, GitLens
* **Ferramenta de Linha de Comando (CLI):** PowerShell / Command Prompt / Terminal Integrado
* **Dispositivos de Teste:** Emulador Android (Pixel API 34) / Terminal CLI Desktop

---

## 2. Instruções para Obtenção do Diagnóstico Real

Para validar se o ambiente local possui todas as dependências e ferramentas instaladas corretamente, execute o seguinte comando no terminal:

```bash
flutter doctor -v
```

Caso o Flutter SDK não esteja configurado no `PATH` global, certifique-se de adicionar a pasta `bin` da instalação do Flutter às variáveis de ambiente do sistema.

---

## 3. Saída do Diagnóstico do Flutter (`flutter doctor -v`)

> **AVISO IMPORTANTE:** O bloco abaixo é o espaço reservado para a inserção dos dados do seu ambiente real. Execute o comando indicado acima no seu computador e substitua o conteúdo do bloco de código a seguir pela saída completa gerada no seu terminal.

```text
[COLE AQUI A SAÍDA REAL DO COMANDO flutter doctor -v]
```

---

## 4. Instruções de Verificação do Dart SDK

Para confirmar a versão exata do compilador Dart instalado:

```bash
dart --version
```

Saída esperada (exemplo):
```text
Dart SDK version: 3.x.x (stable) (date) on "windows_x64"
```
