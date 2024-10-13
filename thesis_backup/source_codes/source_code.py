import tkinter as tk
from app.app import App

def main():
    root = tk.Tk()
    app = App(root, device_index=0)  # 必要に応じてデバイスインデックスを変更
    root.mainloop()

if __name__ == "__main__":
    main()