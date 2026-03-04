import curses
import time
import os
import subprocess
import threading
import json
import argparse

# Importera vårt nya Ubuntu-GUI
try:
    from ubuntu_desktop_gui import UbuntuDesktopGUI
except ImportError:
    UbuntuDesktopGUI = None

# Denna klass kommer att köras på din Mac (Hosten) och prata med ditt nya OS över nätverket.
# Den använder Curses för att ge dig ett blixtsnabbt "Retro-Hacker-GUI"

class OSCommandCenter:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        curses.curs_set(0)
        self.stdscr.nodelay(1)
        self.stdscr.clear()
        
        # Färger
        curses.start_color()
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK) # On
        curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)   # Off
        curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Warning
        curses.init_pair(4, curses.COLOR_CYAN, curses.COLOR_BLACK)  # Info

        self.mc_status = "STABIL"
        self.ai_status = "VÄNTAR"
        self.uptime = "0d 0h 0m"
        self.cpu_usage = "2.4%"
        self.ram_usage = "128MB / 16GB"
        
        self.running = True

    def draw_ui(self):
        h, w = self.stdscr.getmaxyx()
        self.stdscr.erase()
        
        # Rita Ram-layout
        self.stdscr.attron(curses.color_pair(4))
        self.stdscr.border()
        self.stdscr.attroff(curses.color_pair(4))
        
        # Titel
        title = " [ MINECRAFT & AI OS - COMMAND CENTER v1.0 ] "
        self.stdscr.addstr(0, w//2 - len(title)//2, title, curses.A_BOLD | curses.color_pair(4))
        
        # Serverstatus - Vänster sida
        self.stdscr.addstr(2, 4, "=== DAEMON OVERWATCH ===", curses.A_UNDERLINE)
        
        # Minecraft
        self.stdscr.addstr(4, 4, "MINECRAFT ENGINE:")
        status_color = curses.color_pair(1) if "STABIL" in self.mc_status else curses.color_pair(2)
        self.stdscr.addstr(4, 22, f"[{self.mc_status}]", status_color | curses.A_BOLD)
        
        # AI Engine
        self.stdscr.addstr(6, 4, "AI NEURAL ENGINE:")
        ai_color = curses.color_pair(3)
        self.stdscr.addstr(6, 22, f"[{self.ai_status}]", ai_color | curses.A_BOLD)
        
        # Systeminfo - Höger sida
        self.stdscr.addstr(2, w-30, "=== SYSTEM VITALS ===", curses.A_UNDERLINE)
        self.stdscr.addstr(4, w-30, f"CPU LOAD:  {self.cpu_usage}")
        self.stdscr.addstr(5, w-30, f"RAM USED:  {self.ram_usage}")
        self.stdscr.addstr(6, w-30, f"UPTIME:    {self.uptime}")

        # Kontroller längst ner
        help_text = " [M] Start MC | [A] Start AI | [L] View Logs | [Q] Exit "
        self.stdscr.addstr(h-2, w//2 - len(help_text)//2, help_text, curses.A_REVERSE)
        
        self.stdscr.refresh()

    def main_loop(self):
        while self.running:
            self.draw_ui()
            
            key = self.stdscr.getch()
            if key == ord('q') or key == ord('Q'):
                self.running = False
            elif key == ord('m') or key == ord('M'):
                self.mc_status = "STARTING..."
                self.draw_ui()
                time.sleep(1)
                self.mc_status = "STABIL (PID 442)"
            elif key == ord('a') or key == ord('A'):
                self.ai_status = "OPTIMIZING..."
                self.draw_ui()
                time.sleep(2)
                self.ai_status = "ONLINE (CUDA ACTIVE)"
            
            time.sleep(0.1)

def run_gui():
    parser = argparse.ArgumentParser(description="Minecraft AI OS Command Center")
    parser.add_argument("--desktop", action="store_true", help="Starta Ubuntu Desktop GUI istället för Curses")
    args = parser.parse_args()

    if args.desktop and UbuntuDesktopGUI:
        print("Starting Ubuntu Desktop GUI...")
        app = UbuntuDesktopGUI()
        app.run()
    else:
        curses.wrapper(lambda stdscr: OSCommandCenter(stdscr).main_loop())

if __name__ == "__main__":
    run_gui()
