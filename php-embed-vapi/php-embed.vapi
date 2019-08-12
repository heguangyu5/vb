// VB.cmd += -X -lm
// VB.cmd += -X -ldl
[CCode (cheader_filename="php-embed.h", lower_case_cprefix="", cprefix="")]
namespace PHP
{
    [CCode (array_length_type="size_t")]
    public uint8[] run_php(string code);
}
