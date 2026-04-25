# Improve startup_log in daemon.rs

1. 检查 startup_log 是否被创建。当前检查没有看到文件被创建。
2. 修改 startup_log 的目录，必须在系统临时文件下的 browser4-$USER/tmp/cli 目录下，如当前应该为 C:\Users\pereg\AppData\Local\Temp\browser4-pereg\tmp\cli。
3. 确保在 daemon.rs 中正确地创建了 startup_log 文件，并且在启动过程中将日志写入该文件。
4. 添加错误处理，以便在无法创建或写入 startup_log 时能够捕获并记录错误信息。

## Reference

[daemon.rs](../../../submodules/Browser4/sdks/browser4-cli/src/daemon.rs)