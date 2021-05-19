module BootStrapK8s


# NODE_ARRAY=$(kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ " "}}{{end}}{{end}}')
#
# echo "Nodes: ${NODE_ARRAY[@]}"
#
# for node in ${NODE_ARRAY[@]}
# do
#     name=$(kubectl get pods --field-selector spec.nodeName=$node -l name=cri-tools -o jsonpath='{range .items[*]}{.metadata.name}')
#     kubectl cp ${1} $name:/tmp/${1}
#     kubectl exec -ti $name -- ctr -n=k8s.io image import /tmp/${1}
# done

# schedulable_nodes() : nodes_json
  # -> pods_by_label(nodes_json, "name=cri-tools") : pods_json
  # -> cp(pods_json, tarred_image) : pods_json
  # -> exec(pods_json, command) : pods_json



  #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/mydir/airgapped.tar.gz
  def self.publish_tarball(output_file : String = "./airgapped.tar.gz")
    #TODO find real images 
    #TODO tar real images 
    s1 = "./spec/fixtures/cnf-testsuite.yml"
    TarClient.tar(output_file, Path[s1].parent, s1.split("/")[-1])
  end
  def self.generate(output_file : String = "./airgapped.tar.gz")
    #TODO find real images 
    #TODO tar real images 
    s1 = "./spec/fixtures/cnf-testsuite.yml"
    TarClient.tar(output_file, Path[s1].parent, s1.split("/")[-1])
  end

  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  def self.extract(output_file : String = "./airgapped.tar.gz")
    #TODO untar real images to their appropriate directories
    #TODO  the second parameter will be determined based on
    # the image file that was tarred
    TarClient.untar(output_file, "./tmp")
  end
  
end

