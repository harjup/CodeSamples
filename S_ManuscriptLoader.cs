using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Xml;

/// <summary>
/// Opens up an XML document associated with the current scene and reads in all the dialog listed
/// Each block of dialog is thrown into a new dialog container and stored on a gameobject named after the dialog ID
/// All the dialog container objects are stored in the heirarchy of a gameobject named "DialogDump".
///
/// Apparently there is an easier way to create objects from xml through object serialization, which I will
/// look into for future projects
/// </summary>
public class S_ManuscriptLoader : MonoBehaviour 
{	
	public GameObject prefab_dialogCont;
	
	//Associates a given Scene name to the XML file it draws dialog from
	private Dictionary<string, string> d_manuFiles = new Dictionary<string, string> 
	{
		{"BeanStreet", "BeanStreetManuscript"},
		{"AppleZone", "AppleZoneManuscript"},
		{"StoryStills01", "StoryStills01"},
		{"StoryStills02", "StoryStills02"},
		{"StoryStills03", "StoryStills03"},
		{"StoryStills025", "StoryStills025"}	
	};
	
	
	void Start () 
	{		
		//Finds the manuscript filename corresponding to the current scene and imports it 
		ImportManuscript(d_manuFiles[Application.loadedLevelName]);		
	}
	
	/// <summary>
	/// Parses through the current XML file, extracts all the relevant data, and stores it in
	/// S_DialogContainer instances
	/// </summary>
	void ImportManuscript(string directory)
	{
		TextAsset xmlFile = Resources.Load(directory) as TextAsset;
		
		string ID = "0";		//ID used to identify a specific dialogContainer
		
		List<string> l_fr = new List<string>();	//List of french phrases, parallel with l_en if used
		List<string> l_en = new List<string>();	//List of english phrases
		List<int> l_num = new List<int>();		//Number of known french words required to understand sentence
		
		using (XmlReader r = XmlReader.Create(new StringReader(xmlFile.text)))
		{
		
			while (r.Read())
			{
				//At the start of a given element (<Example>), check its name
				//and branch accordingly
				if (r.IsStartElement())
				{
					switch (r.Name)
					{
					case "Dialog":
						ID = r["ID"];
						
						l_en = new List<string>();
						l_fr = new List<string>();
						l_num = new List<int>();
						break;
					case "Text":
						//Grab all the attributes in the Start Element
						
						string language = r["lang"];
						int num = -1;
						if (language == "fr")
						{
							num = System.Convert.ToInt32(r["num"]);	
						}
						//Proceed to the contents of the Element
						r.Read();
						string textValue = r.Value;

						
						
						//Create a new C_Text instance and add it to the list for sending to a container
						
						if (language == "fr")
						{	
							l_fr.Add(textValue);
							l_num.Add(num);
						}
						else if (language == "en")
						{;	
							l_en.Add(textValue);	
						}
						else
						{
							l_en.Add(textValue);
						}
						
						break;
						
					default:
						break;
					}
				}
				//Runs at the </Dialog> tag...
				else if (r.Name == "Dialog")
				{	
					List<C_Text> l_text = new List<C_Text>();
					
					//Build the textlist here
					for (int i = 0; i < l_en.Count; i++) 
					{		
						if (l_fr.Count == l_en.Count)
						{
							l_text.Add(new C_Text(l_en[i],l_fr[i], l_num[i]));
						}
						else
						{
							l_text.Add(new C_Text(l_en[i]));
						}
						
					}
					
					CreateDialogContainer(l_text, ID);
				}
			}
			
			
		}
		
	}
	
	/// <summary>
	/// Creates a dialog container
	/// </summary>
	/// <param name='text'>
	/// The list of text objects held by the created container
	/// </param>
	/// <param name='id'>
	/// Container identifier
	/// </param>
	void CreateDialogContainer(List<C_Text> text, string id)
	{
		GameObject dialogDump;
		
		if (GameObject.Find("DialogDump") == null)
		{
			dialogDump = new GameObject("DialogDump");
		}
		else
		{
			dialogDump = GameObject.Find("DialogDump");
		}
		
							
		GameObject dialogContainer = Instantiate(prefab_dialogCont) as GameObject;
		dialogContainer.name = "DialogContainer";										//Name the dialog container "DialogContainer"
		dialogContainer.GetComponent<S_DialogContainer>().DialogInit(text);				//Insert the loaded text into the container
						
						
		GameObject idObject = new GameObject(id);											//Create an ID gameobject used to find the dialog
		idObject.transform.parent = dialogContainer.transform;								//It sits in the same directory
						
		dialogContainer.transform.parent = dialogDump.transform;						//Make the container a child of dialogDump
	}
	
}
