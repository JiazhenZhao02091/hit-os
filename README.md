### Record some condition about hit-os.

## 实验一

- 制作镜像

```shell
cd ~/oslab/linux-0.11
make all 
```

- 启动镜像

```shell
cd ~/oslab/
./run
```

- 调试
  - 汇编级调试
  
  ```shell
  cd ~/oslab
  ./dbg-asm
  ```
  
  - C语言级调试

    启动一个窗口

    ```shell
    cd ~/oslab
    ./dbg-c
    ```
    再启动一个窗口
    ```shell
    cd ~/oslab
    ./rungdb
    ```

- 文件交换
```shell
cd ~/oslab/
sudo ./mount-hdc
# 进入挂载后的目录
cd ~/oslab/hdc
ls-al
# 卸载文件系统
cd ~/oslab/
sudo umount hdc
```