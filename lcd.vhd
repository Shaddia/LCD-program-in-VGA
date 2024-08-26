library ieee ;
use ieee.std_logic_1164.all;

-----------------------------------------------------

entity lcd is
port(clk:		in std_logic;    --Clock to keep trak of time
	lcd:		out std_logic_vector(7 downto 0);  --LCD data pins
	enviar : out std_logic;    --Send signal
	rs:		out std_logic;    --Data or command
	rw: out std_logic;    --read/write
	mul:     in     std_logic;
	div:     in     std_logic;
	sum:     in     std_logic;
	res:     in     std_logic;
	ps2_data    :   in std_logic;
	ps2_clock : in  std_logic);
end lcd;

-----------------------------------------------------

architecture FSM of lcd is
	signal i : integer := 0;
	signal j : integer := 0;
	signal h : integer := 0;
	signal k : integer := 0;
	signal sumador: integer := 2000;

	type tipo_estado is (e0,e1,e2);
	signal estado_siguiente, estado_actual: tipo_estado;
	signal code,teclaanterior,sig0,sig1,sig2 : std_logic_vector(10 downto 0);
	signal tecla: std_logic_vector(10 downto 0) := "00000000000";
	 function lcdd(h: in integer)
					return std_logic_vector is
			variable resultado: std_logic_vector(7 downto 0);
	 begin
			case h is
				when 0 => resultado := "00110000";
				when 1 => resultado := "00110001";
				when 2 => resultado := "00110010";
				when 3 => resultado := "00110011";
				when 4 => resultado := "00110100";
				when 5 => resultado := "00110101";
				when 6 => resultado := "00110110";
				when 7 => resultado := "00110111";
				when 8 => resultado := "00111000";
				when 9 => resultado := "00111001";
				when others => resultado := "00110000";
			end case;
			return resultado;
	end function;
    type state_type is (encender, configpantalla,encenderdisplay, limpiardisplay, configcursor,listo,fin);    --Define dfferent states to control the LCD
    signal estado: state_type;
	 type cadena is array (0 to 7) of std_logic_vector(7 downto 0);
	 signal mensaje: cadena:=
	 ("01001000",
	 "01101111",
	 "01101100",
	 "00101110",
	 "00100000",
	 "01101101",
	 "01110101", "00000000");
	 constant milisegundos: integer := 50000;
	 constant microsegundos: integer := 50;
begin
    state_reg: process(ps2_clock)
    begin
		if (ps2_clock' event and ps2_clock = '0') then
			code(i)<=ps2_data;
			i<=i+1;
			if(i=10) then
				teclaanterior <= tecla;
				tecla<=code;
				
				i<=0;
				estado_actual <= estado_siguiente;
			end if;
		end if;
	end process;
	estados: process(estado_actual,tecla)
	begin
		case estado_actual is
			when e0 => 	estado_siguiente<=e1;
							sig0 <= tecla;
			when e1 => 	estado_siguiente<=e2;
							sig1 <= tecla;
			when e2 => 	estado_siguiente<=e0;
							sig2 <= tecla;
			when others => 	estado_siguiente<=e0;
							sig0 <= "11111111111";
							sig1 <= "11111111111";
							sig2 <= "11111111111";
		end case;
	end process;
  comb_logic: process(clk)
  variable contar,indice: integer := 0;
  variable sumador: integer := 2000;
  begin
	
	
	
	if (clk'event and clk='1') then
	  case estado is
	    when encender =>
		  if (contar < 50*milisegundos) then    --Wait for the LCD to start all its components
				contar := contar + 1;
				estado <= encender;
			else
				enviar <= '0';
				contar := 0;
	 			mensaje(0) <= lcdd(sumador/100000); 
	 			mensaje(1) <= lcdd((sumador/10000) mod 10); 
	 			mensaje(2) <= lcdd((sumador/1000) mod 10); 
	 			mensaje(4) <= lcdd((sumador/100) mod 10); 
	 			mensaje(5) <= lcdd((sumador/10) mod 10); 
				mensaje(6) <= lcdd(sumador mod 10); 
				estado <= configpantalla;
			end if;
			--From this point we will send diffrent configuration commands as shown in class
			--You should check the manual to understand what configurations we are sending to
			--The display. You have to wait between each command for the LCD to take configurations.
	    when configpantalla =>
			if (contar = 0) then
				contar := contar +1;
				rs <= '0';
				rw <= '0';
				lcd <= "00111000";
				enviar <= '1';
				estado <= configpantalla;
			elsif (contar < 1*milisegundos) then
				contar := contar + 1;
				estado <= configpantalla;
			else
				enviar <= '0';
				contar := 0;
				estado <= encenderdisplay;
			end if;
	    when encenderdisplay =>
			if (contar = 0) then
				contar := contar +1;
				lcd <= "00001110";				
				enviar <= '1';
				estado <= encenderdisplay;
			elsif (contar < 1*milisegundos) then
				contar := contar + 1;
				estado <= encenderdisplay;
			else
				enviar <= '0';
				contar := 0;
				estado <= limpiardisplay;
			end if;
	    when limpiardisplay =>	
			if (contar = 0) then
				contar := contar +1;
				lcd <= "00000001";				
				enviar <= '1';
				estado <= limpiardisplay;
			elsif (contar < 1*milisegundos) then
				contar := contar + 1;
				estado <= limpiardisplay;
			else
				enviar <= '0';
				contar := 0;
				estado <= configcursor;
			end if;
	    when configcursor =>	
			if (contar = 0) then
				contar := contar +1;
				lcd <= "00000100";				
				enviar <= '1';
				estado <= configcursor;
			elsif (contar < 1*milisegundos) then
				contar := contar + 1;
				estado <= configcursor;
			else
				enviar <= '0';
				contar := 0;
				estado <= listo;
			end if;
			--The display is now configured now it you just can send data to de LCD 
			--In this example we are just sending letter A, for this project you
			--Should make it variable for what has been pressed on the keyboard.
	    when listo =>	
			if (contar = 0) then
				rs <= '1';
				rw <= '0';
				enviar <= '1';
				lcd <= mensaje(indice); -- ascii de A
				indice := indice+1;
				if (indice = 8) then
				    indice := 0;
					 estado <= fin;
			   else
					 estado <= listo;
				end if;
				contar := contar +1;
			elsif (contar < 5*milisegundos) then
				contar := contar + 1;
				estado <= listo;
			else
				enviar <= '0';
				contar := 0;
				estado <= listo;
			end if;
		  when fin =>
		  
		  		if (tecla (8 downto 1) = x"F0" and k = 0) then
					case teclaanterior(8 downto 1) is
						when x"43" =>
							j <= 1;
							k <= 1;
						when x"1b" =>
							j <= 2;
							k <= 1;
						when x"23" =>
							j <= 3;
							k <= 1;
						when x"33" =>
							j <= 4;
							k <= 1;
						when others =>
							k <= 0;	
					end case;
				else
					if(tecla (8 downto 1) /= x"F0" ) then
						k <= 0;
					end if;
					j <= 0;
				end if;
		  
			if (mul = '0' or div = '0' or res = '0'or sum = '0' or j /= 0) then

				if(mul = '0' or j = 3) then
					if (sumador>=500000) then
						sumador := 999999;
					else
						sumador := sumador*2;
					end if;
				end if;
				if(div = '0' or j = 4) then
					sumador := sumador/2;
				end if;
				if(sum = '0' or j = 1) then
					if (sumador>=999000) then
						sumador := 999999;
					else
						sumador := sumador+1000;
					end if;
				end if;
				if(res = '0' or j = 2) then
					if (sumador<= 1000) then
						sumador := 0;
					else
						sumador := sumador-1000;
					end if;
				end if;
				estado <= encender;
			else
				estado <= fin;
			end if;
	    when others =>
			estado <= encender;
	  end case;
	end if;
 end process;
end FSM;