// VB.cmd += -X -lm
// VB.cmd += -X -ldl
// VB.cmd += -X -L/usr/lib/oracle/11.2/client64/lib/
// VB.cmd += -X -lclntsh
[CCode (cheader_filename="php-embed.h", lower_case_cprefix="php_", cprefix="")]
namespace PHP
{
    public bool startup();
    public void shutdown();

    public bool req_startup(bool main_thread = true);
    public bool req_shutdown(bool main_thread = true);

    public void execute(string code);
    [CCode (array_length_type="size_t")]
    public uint8[]? execute_return_string(string code);
}
