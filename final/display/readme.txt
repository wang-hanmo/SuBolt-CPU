目录结构：
   +--gzrom_origin.bin/            : PMON启动文件
   |        
   |--readme.txt/                       : 本文档
   |
   |--soc_up_top.bit/                 : 系统展示比特流
   |
   |--ucore-display/                  : ucore系统展示内核（ls,cat,pwd,showNumber）
   |
   |--vmlinux-display/                : linux系统展示内核（未完全启动）


ucore展示内核命令：
ls：		查看目录
cat:		显示文件内容
pwd:		显示当前路径
showNumber:	互动命令，使用4*4按键输入，控制数码管或LED灯，
		使用下侧脉冲开关返回命令行