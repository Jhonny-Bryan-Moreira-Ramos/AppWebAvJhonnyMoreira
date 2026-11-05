using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.PoliMusicV3
{
    /// <summary>
    /// Capa de negocio de las canciones. Actúa como intermediaria entre la
    /// presentación (Song.aspx) y la capa de acceso a datos (DAL.PoliMusicV3.Song).
    /// </summary>
    public class Song
    {
        private string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        /// <summary>
        /// Listado de canciones como DataTable.
        /// </summary>
        public DataTable Read()
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read();
        }

        /// <summary>
        /// Una canción por identificador como DataTable.
        /// </summary>
        public DataTable Read(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read(idSong);
        }

        /// <summary>
        /// Listado de canciones ya tipado con la entidad EntityLayer.PoliMusicV3.Song,
        /// que es lo que consume la capa de presentación.
        /// </summary>
        public List<EntityLayer.PoliMusicV3.Song> GetSongs()
        {
            List<EntityLayer.PoliMusicV3.Song> listSongs = new List<EntityLayer.PoliMusicV3.Song>();
            DataTable dtSong = Read();
            if (dtSong == null)
            {
                return listSongs;
            }
            foreach (DataRow row in dtSong.Rows)
            {
                EntityLayer.PoliMusicV3.Song song = new EntityLayer.PoliMusicV3.Song();
                song.ID = Convert.ToInt32(row["ID_SONG"]);
                song.SongName = row["SONG_NAME"].ToString();
                song.SongPath = row["SONG_PATH"].ToString();
                song.Plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
                listSongs.Add(song);
            }
            return listSongs;
        }

        public int Save(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Save(song);
        }

        public int Update(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Update(song);
        }

        public int Delete(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Delete(idSong);
        }

        public int IncreasePlays(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).IncreasePlays(idSong);
        }
    }

}
