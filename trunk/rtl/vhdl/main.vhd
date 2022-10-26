library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ddfs is
	generic (
		-- Width of used Digitial-Analog-Converter.
		DAwidth : positive := 10
	);
	port (
		-- System clock.
		clk : in std_logic;

		freq_data : in std_logic_vector(DAwidth-1 downto 0);

		dout : out std_logic_vector(DAwidth-1 downto 0)
	);
end ddfs;

architecture ddfs_arch of ddfs is
	signal s_data : std_logic_vector(DAwidth-1 downto 0);
	signal s_result : std_logic_vector(DAwidth-1 downto 0);
	signal s_accum : unsigned(20 downto 0); -- for what?
	signal s_address : unsigned(5 downto 0) is s_accum(s_accum'high-2 downto s_accum'high-7);
	signal s_sign : std_logic is s_accum(s_accum'high); -- MSB
	signal s_quadrant : std_logic is s_accum(s_accum'high-1);
begin
	-- Phasenakkumulator
	process(clk)
	begin
		if rising_edge(clk) then
			s_accum <= s_accum + unsigned(freq_data);
		end if;
	end process;

	-- Combinatorial process.
	process(s_sign, s_quadrant, s_address)
		subtype SLVX is std_logic_vector(DAwidth-1 downto 0);
		type ROM64xX is array (0 to 63) of SLVX; -- siehe Artikel http://www.mikrocontroller.net/articles/Digitale_Sinusfunktion
		constant Sinus_ROM : ROM64xX := (       
			x"02",  x"05",  x"08",  x"0b",  x"0e",  x"11",  x"14",  x"17",
		      x"1a",  x"1d",  x"20",  x"23",  x"26",  x"29",  x"2c",  x"2f",
       		x"32",  x"36",  x"39",  x"3c",  x"3e",  x"40",  x"43",  x"46",
       		x"48",  x"4b",  x"4d",  x"50",  x"52",  x"54",  x"57",  x"59",
       		x"5b",  x"5d",  x"5f",  x"62",  x"64",  x"65",  x"67",  x"69",
       		x"6b",  x"6d",  x"6e",  x"70",  x"71",  x"73",  x"74",  x"75",
       		x"76",  x"77",  x"79",  x"79",  x"7a",  x"7b",  x"7c",  x"7d",
       		x"7d",  x"7e",  x"7e",  x"7f",  x"7f",  x"7f",  x"7f",  x"7f"
		);
	begin
		if s_quadrant = '0' then
			s_result <= Sinus_ROM(to_integer(s_address));
		else
			s_result <= Sinus_ROM(63-to_integer(s_address));
		end if;
		if s_sign = '1' then
			s_data <= s_result;
		else
			s_data <= std_logic_vector(-signed(s_result));
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			dout <= s_data;
		end if;
	end process;
end architecture ddfs_arch;