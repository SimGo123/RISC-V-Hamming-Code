# Hamming Code Encoder and Decoder
Encode and decode [Hamming Code](https://en.wikipedia.org/wiki/Hamming_code) in RISC V Assembler.
To program in RISC V Assembler I recommend using [RARS](https://github.com/TheThirdOne/rars) as Simulator and Runtime.
## Usage
When running this program, you are prompted to choose whether you want to encode or decode input.\
To decode just press `d`, to encode `e`.\
In both cases you are now being asked for input data. It has to be binary (`1`s and `0`s). Then hit `enter`.\
After finishing, the program outputs the `corr bits`, meaning the parity that was calculated from the input.
- If you were encoding data, these corr bits are inserted into the input string.
- If you chose to decode your input, the calculated corr bits will indicate whether there is a one bit error or not.\
If there is one, the program will correct it automatically and output the 
corrected data with and without the corr bits.\
The input data without the corr bits will also be printed.
