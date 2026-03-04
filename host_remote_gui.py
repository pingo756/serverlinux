import curses
import socket
import json
import time
import threading

class RemoteTUIClient:
    def __init__(self, stdscr, server_ip="127.0.0.0", server_port=5555):
        self.stdscr = stdscr
        self.server_ip = server_ip # Byt till OS-maskinens riktiga IP när den är byggd
        self.server_port = server_port
        self.network_socket = None
        self.connected = False
        self.status_data = {"minecraft_status": "UNKNOWN", "ai_status": "UNKNOWN"}
        
        # Sätt upp GUI
        curses.curs_set(0)
        self.stdscr.nodelay(1)
        curses.start_color()
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)

    def connect_to_os(self):
        """ Försöker ansluta var 3:e sekund i bakgrunden """
        while True:
            if not self.connected:
                try:
                    self.network_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    self.network_socket.connect((self.server_ip, self.server_port))
                    self.connected = True
                except:
                    time.sleep(3)
            else:
                # Polla servern på status
                try:
                    self.network_socket.sendall(json.dumps({"action": "GET_STATUS"}).encode('utf-8'))
                    response = self.network_socket.recv(1024).decode('utf-8')
                    self.status_data = json.loads(response)
                except:
                    self.connected = False
                    self.network_socket.close()
                time.sleep(1)

    def send_command(self, action):
        if self.connected:
            try:
                self.network_socket.sendall(json.dumps({"action": action}).encode('utf-8'))
            except:
                pass

    def run(self):
        # Starta nätverksklienten i bakgrunden
        threading.Thread(target=self.connect_to_os, daemon=True).start()

        while True:
            self.stdscr.clear()
            self.stdscr.box()
            self.stdscr.addstr(0, 5, " REMOTE OS CONTROLLER (Host) ", curses.A_BOLD)

            if not self.connected:
                self.stdscr.addstr(2, 4, f"Status: Söker efter server på {self.server_ip}...", curses.color_pair(2))
            else:
                self.stdscr.addstr(2, 4, f"Status: LÄNKUPPKOPPLAD MOT OS!", curses.color_pair(1))
                self.stdscr.addstr(4, 4, f"Minecraft Demon: {self.status_data.get('minecraft_status', 'N/A')}")
                self.stdscr.addstr(5, 4, f"AI Demon:        {self.status_data.get('ai_status', 'N/A')}")

            self.stdscr.addstr(8, 4, "[S] Skicka start-signal till Minecraft")
            self.stdscr.addstr(9, 4, "[Q] Avsluta Remote Host")

            self.stdscr.refresh()
            
            key = self.stdscr.getch()
            if key == ord('q'):
                break
            elif key == ord('s'):
                self.send_command("START_MINECRAFT")
                
            time.sleep(0.1)

def start_remote():
    curses.wrapper(lambda stdscr: RemoteTUIClient(stdscr).run())

if __name__ == "__main__":
    start_remote()