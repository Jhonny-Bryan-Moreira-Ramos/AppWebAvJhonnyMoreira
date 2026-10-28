using System;
using System.Collections.Generic;
using System.Data;
using System.Web;

namespace WebAppPoliMusicV2.BLL
{
    public class Song
    {
        private string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Save(song);
        }

        public DataTable Read()
        {
            return new DAL.Song(strConnectionString).Read();
        }

        public DataTable Read(int idSong)
        {
            return new DAL.Song(strConnectionString).Read(idSong);
        }

        public int Update(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Update(song);
        }

        public int Delete(int idSong)
        {
            return new DAL.Song(strConnectionString).Delete(idSong);
        }

        public int IncreasePlays(int idSong)
        {
            return new DAL.Song(strConnectionString).IncreasePlays(idSong);
        }

        /// <summary>
        /// Business rules for a song before it is saved
        /// </summary>
        /// <returns>An empty string if the song is valid or the error message</returns>
        public string Validate(Entities.Song song)
        {
            if (song == null)
            {
                return "The song is required.";
            }
            if (string.IsNullOrEmpty(song.SongName) || song.SongName.Trim().Length == 0)
            {
                return "The song name is required.";
            }
            if (song.SongName.Trim().Length > 50)
            {
                return "The song name can not be longer than 50 characters.";
            }
            if (string.IsNullOrEmpty(song.SongPath) || song.SongPath.Trim().Length == 0)
            {
                return "The song path is required.";
            }
            if (song.SongPath.Trim().Length > 255)
            {
                return "The song path can not be longer than 255 characters.";
            }
            if (song.Plays < 0)
            {
                return "The number of plays can not be negative.";
            }
            return string.Empty;
        }
    }

}
