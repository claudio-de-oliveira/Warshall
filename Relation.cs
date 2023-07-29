using System.Data.SqlClient;

namespace Warshall
{
    public class Relation
    {
        private readonly SqlConnection sqlConnection;

        public Relation(string sqlConnectionString)
        {
            sqlConnection = new(sqlConnectionString);

            Inicializar();
        }

        private void Inicializar()
        {
            try
            {
                sqlConnection.Open();

                SqlCommand sqlCommand = sqlConnection.CreateCommand();

                sqlCommand.CommandText = @"
                    USE Warshall

                    DELETE FROM Relation
                    DELETE FROM Items
                    DELETE FROM Through
                    DELETE FROM Forest
                ";
                sqlCommand.ExecuteNonQuery();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                sqlConnection.Close();
            }
        }

        public void AddPair(string a, string b)
        {
            try
            {
                sqlConnection.Open();

                SqlCommand sqlCommand = sqlConnection.CreateCommand();

                sqlCommand.CommandText = $"exec AddPair '{a}', '{b}'";
                sqlCommand.ExecuteNonQuery();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                sqlConnection.Close();
            }
        }

        public void RemovePair(string a, string b)
        {
            try
            {
                sqlConnection.Open();

                SqlCommand sqlCommand = sqlConnection.CreateCommand();

                sqlCommand.CommandText = $"exec RemovePair '{a}', '{b}'";
                sqlCommand.ExecuteNonQuery();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                sqlConnection.Close();
            }
        }

        public List<string> GetEquivalents(string x)
        {
            List<string> list = new();

            try
            {
                sqlConnection.Open();

                SqlCommand sqlCommand = sqlConnection.CreateCommand();

                sqlCommand.CommandText = $"Select * FROM GetEquivalents('{x}')";
                SqlDataReader dataReader = sqlCommand.ExecuteReader();

                while (dataReader.Read())
                    list.Add(dataReader.GetString(0));

                dataReader.Close();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                sqlConnection.Close();
            }

            return list;
        }
    }
}
