using Warshall;

Relation relation = new(@"Data Source=<<Server>>;Initial Catalog=Warshall;Integrated Security=True");

int Max = 10; /* Max < 50 */

try
{
    for (int i = 0; i < Max - 1; i += 2)
    {
        relation.AddPair($"A{i}", $"A{i + 1}");
        relation.AddPair($"B{i}", $"B{i + 1}");
        relation.AddPair($"C{i}", $"C{i + 1}");
        relation.AddPair($"D{i}", $"D{i + 1}");
    }

    await Task.Delay(TimeSpan.FromSeconds(1));

    for (int i = 1; i < Max - 2; i += 2)
    {
        relation.AddPair($"A{i}", $"A{i + 1}");
        relation.AddPair($"B{i}", $"B{i + 1}");
        relation.AddPair($"C{i}", $"C{i + 1}");
        relation.AddPair($"D{i}", $"D{i + 1}");
    }

    await Task.Delay(TimeSpan.FromSeconds(1));

    relation.AddPair("A0", "B0");
    await Task.Delay(TimeSpan.FromSeconds(1));
    relation.AddPair("C0", "D0");
    await Task.Delay(TimeSpan.FromSeconds(1));
    relation.AddPair("A0", "D0");
    await Task.Delay(TimeSpan.FromSeconds(1));

    relation.RemovePair("A0", "B0");
    await Task.Delay(TimeSpan.FromSeconds(1));
    relation.RemovePair("C0", "D0");
    await Task.Delay(TimeSpan.FromSeconds(1));
    /* Pairs from transitive closure can't be removed (use "A0", "D0" instead) */
    relation.RemovePair("A0", "D1");
    await Task.Delay(TimeSpan.FromSeconds(1));

    var similiaresA = relation.GetEquivalents("A0");
    var similiaresB = relation.GetEquivalents("B0");
    var similiaresC = relation.GetEquivalents("C0");
    var similiaresD = relation.GetEquivalents("D0");
}
catch (Exception ex)
{
    Console.WriteLine(ex.Message);
}
Console.ReadLine();

