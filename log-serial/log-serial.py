#!/usr/bin/env python3

import serial
import sys
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime


if len(sys.argv) < 3:
    print("Usage: ./log-serial.py <file_path> <serial_port>")
    sys.exit(1)

file_path = sys.argv[1]
serial_port = sys.argv[2]

serport = serial.Serial(baudrate=115200)
serport.setPort(serial_port)
serport.open()

# Don't reset the MMC but drive the P2.10 pin to HIGH, so it can be reset
# externally and execute the application code, not the ROM bootloader
serport.setRTS(0)  # set RTS line to 3.3V
serport.setDTR(0)  # set DTR line to 3.3V

logger = logging.getLogger('serial_logger')
logger.setLevel(logging.INFO)

formatter = logging.Formatter(
    fmt='[%(asctime)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# Rotating file handler (10MB per file, keep 5 backups)
file_handler = RotatingFileHandler(
    file_path,
    maxBytes=10*1024*1024,
    backupCount=5
)
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

while True:
    try:
        message = serport.readline().decode("utf-8", errors="replace").strip()
        logger.info(message)
    except serial.SerialException:
        logger.error("Serial port disconnected. Shutting down...")
        break
