using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Web.UI.WebControls;
using SongEntity = EntityLayer.PoliMusicV3.Song;

namespace WebAppPoliMusicV3
{
    /// <summary>
    /// Listado de canciones (tabla TBL_SONG) con un reproductor de audio HTML5
    /// por fila. Los datos se obtienen de la capa de negocio (BLL.PoliMusicV3.Song).
    /// </summary>
    public partial class Song : System.Web.UI.Page
    {
        private readonly string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        /// <summary>Carpeta donde viven los archivos .mp3.</summary>
        private const string SONG_FOLDER = "~/SongFiles/";

        private List<SongEntity> listSongs = new List<SongEntity>();

        protected void Page_Load(object sender, EventArgs e)
        {
            // La página solo trabaja con un usuario autenticado
            // (Session[USER] se escribe en Login.aspx).
            if (Session[EntityLayer.PoliMusicV3.Util.Constants.USER] == null)
            {
                Response.Redirect("~/Login", true);
                return;
            }

            LoadSongs();
        }

        /// <summary>
        /// Obtiene las canciones desde la BLL y las enlaza al GridView.
        /// </summary>
        private void LoadSongs()
        {
            listSongs = new List<SongEntity>();
            pnlError.Visible = false;
            litError.Text = string.Empty;

            try
            {
                listSongs = new BLL.PoliMusicV3.Song(strConnString).GetSongs();
            }
            catch (Exception ex)
            {
                listSongs = new List<SongEntity>();
                pnlError.Visible = true;
                litError.Text = " " + Server.HtmlEncode(ex.Message);
            }

            gvSongs.DataSource = listSongs;
            gvSongs.DataBind();

            litTotalSongs.Text = listSongs.Count.ToString();
            litTotalPlays.Text = TotalPlays.ToString();
            litCurrentUser.Text = Server.HtmlEncode(UserName);
        }

        /// <summary>
        /// Marca la fila de cabecera como &lt;thead&gt; para que sea accesible
        /// y se pueda estilizar.
        /// </summary>
        protected void gvSongs_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.Header)
            {
                e.Row.TableSection = TableRowSection.TableHeader;
            }
        }

        #region Propiedades expuestas a la vista (Song.aspx)

        /// <summary>
        /// Usuario autenticado guardado en la sesión.
        /// </summary>
        protected EntityLayer.PoliMusicV3.User CurrentUser
        {
            get { return Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User; }
        }

        /// <summary>
        /// Nombre del usuario autenticado.
        /// </summary>
        protected string UserName
        {
            get { return (CurrentUser == null) ? string.Empty : CurrentUser.UserName; }
        }

        /// <summary>
        /// Suma de las reproducciones de todas las canciones.
        /// </summary>
        protected int TotalPlays
        {
            get
            {
                int intTotal = 0;
                foreach (SongEntity song in listSongs)
                {
                    intTotal += song.Plays;
                }
                return intTotal;
            }
        }

        #endregion

        #region Helpers usados desde el marcado (Song.aspx)

        /// <summary>
        /// URL del archivo de audio a partir del valor de SONG_PATH.
        /// Se enlaza directamente en el atributo src del elemento &lt;audio&gt;.
        /// </summary>
        protected string SongUrl(object songPath)
        {
            string strLogicalPath = ToLogicalPath(songPath);
            return string.IsNullOrEmpty(strLogicalPath) ? string.Empty : ResolveUrl(strLogicalPath);
        }

        /// <summary>
        /// Indica si el archivo de audio existe físicamente en el servidor.
        /// </summary>
        protected bool SongFileExists(object songPath)
        {
            string strLogicalPath = ToLogicalPath(songPath);
            if (string.IsNullOrEmpty(strLogicalPath))
            {
                return false;
            }
            try
            {
                string strPhysicalPath = Server.MapPath(strLogicalPath);
                return !string.IsNullOrEmpty(strPhysicalPath) && File.Exists(strPhysicalPath);
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Normaliza el valor de SONG_PATH a una ruta lógica del tipo "~/SongFiles/x.mp3".
        /// Acepta rutas con "~", rutas relativas y también solo el nombre del archivo.
        /// </summary>
        private string ToLogicalPath(object songPath)
        {
            string strPath = Convert.ToString(songPath).Trim().Replace('\\', '/');
            if (strPath.Length == 0)
            {
                return string.Empty;
            }

            string strLogicalPath;
            if (strPath.StartsWith("~"))
            {
                strLogicalPath = "~/" + strPath.TrimStart('~', '/');
            }
            // Rutas relativas del tipo "../songFiles/x.mp3" o "./songFiles/x.mp3":
            // se toma el nombre del archivo y se asume la carpeta ~/SongFiles/
            else if (strPath.StartsWith("..") || strPath.StartsWith("./"))
            {
                int intSlash = strPath.LastIndexOf('/');
                strLogicalPath = SONG_FOLDER + ((intSlash >= 0) ? strPath.Substring(intSlash + 1) : strPath);
            }
            // Solo el nombre del archivo: se asume la carpeta ~/SongFiles/
            else if (strPath.IndexOf('/') < 0)
            {
                strLogicalPath = SONG_FOLDER + strPath;
            }
            else if (strPath.StartsWith("/"))
            {
                strLogicalPath = "~" + strPath;
            }
            else
            {
                strLogicalPath = "~/" + strPath;
            }

            // La base de datos guarda "~/songFiles/..." y la carpeta del
            // proyecto se llama "SongFiles": se unifica el nombre.
            const string strSongFilesPath = "~/songfiles/";
            if (strLogicalPath.StartsWith(strSongFilesPath, StringComparison.OrdinalIgnoreCase))
            {
                strLogicalPath = SONG_FOLDER + strLogicalPath.Substring(strSongFilesPath.Length);
            }

            return strLogicalPath;
        }

        #endregion
    }
}
