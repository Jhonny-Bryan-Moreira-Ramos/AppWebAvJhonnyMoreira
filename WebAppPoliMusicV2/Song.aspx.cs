using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.UI;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        private List<Entities.Song> listSongs = new List<Entities.Song>();
        private string strErrorMessage = string.Empty;

        protected void Page_Load(object sender, EventArgs e)
        {
            // The page only works with an authenticated user (Session[USER] is set in Login.aspx)
            if (Session[Util.Constants.USER] == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }
            if (!Page.IsPostBack)
            {
                LoadSongs();
            }
        }

        /// <summary>
        /// Read the songs from the database and fill the entity list
        /// </summary>
        private void LoadSongs()
        {
            listSongs = new List<Entities.Song>();
            strErrorMessage = string.Empty;
            try
            {
                DataTable dtSong = new BLL.Song(strConnString).Read();
                if (dtSong == null)
                {
                    return;
                }
                foreach (DataRow row in dtSong.Rows)
                {
                    Entities.Song song = new Entities.Song();
                    song.ID = Convert.ToInt32(row["ID_SONG"]);
                    song.SongName = row["SONG_NAME"].ToString();
                    song.SongPath = row["SONG_PATH"].ToString();
                    song.Plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
                    listSongs.Add(song);
                }
            }
            catch (Exception ex)
            {
                listSongs = new List<Entities.Song>();
                strErrorMessage = ex.Message;
            }
        }

        #region Data exposed to the view (Song.aspx)

        /// <summary>
        /// Authenticated user stored in the session
        /// </summary>
        protected Entities.User CurrentUser
        {
            get { return Session[Util.Constants.USER] as Entities.User; }
        }

        /// <summary>
        /// Name of the authenticated user (shown in the top bar)
        /// </summary>
        protected string UserName
        {
            get { return (CurrentUser == null) ? string.Empty : CurrentUser.UserName; }
        }

        /// <summary>
        /// Photo of the authenticated user, using the default image as fallback
        /// </summary>
        protected string UserPhotoUrl
        {
            get
            {
                string strPhoto = (CurrentUser == null) ? string.Empty : CurrentUser.Photo;
                if (string.IsNullOrEmpty(strPhoto) || strPhoto.Trim().Length == 0)
                {
                    strPhoto = "~/UserImages/default.jpg";
                }
                return ResolveUrl(strPhoto.Trim());
            }
        }

        /// <summary>
        /// Songs read from [TBL_SONG]
        /// </summary>
        protected List<Entities.Song> Songs
        {
            get { return listSongs; }
        }

        /// <summary>
        /// Sum of the plays of every song
        /// </summary>
        protected int TotalPlays
        {
            get
            {
                int total = 0;
                foreach (Entities.Song song in listSongs)
                {
                    total += song.Plays;
                }
                return total;
            }
        }

        /// <summary>
        /// Error message when the catalog could not be loaded
        /// </summary>
        protected string ErrorMessage
        {
            get { return strErrorMessage; }
        }

        #endregion

        #region Helpers used in the markup

        /// <summary>
        /// Convert the logical path of the database (~/songFiles/x.mp3) into a valid url
        /// </summary>
        protected string SongUrl(string songPath)
        {
            if (string.IsNullOrEmpty(songPath))
            {
                return string.Empty;
            }
            string strPath = songPath.Trim();
            if (strPath.StartsWith("~/"))
            {
                return ResolveUrl(strPath);
            }
            if (strPath.StartsWith("~"))
            {
                return ResolveUrl("~/" + strPath.TrimStart('~', '/'));
            }
            return strPath;
        }

        /// <summary>
        /// Html encode a value before writing it in the page
        /// </summary>
        protected string H(string value)
        {
            return HttpUtility.HtmlEncode((value == null) ? string.Empty : value);
        }

        #endregion
    }
}
