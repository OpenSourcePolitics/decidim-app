--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2
-- Dumped by pg_dump version 14.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version) FROM stdin;
20180611124757
20180611124758
20180611124759
20180611124760
20180611124761
20180611124762
20180611124763
20180611124764
20180611124765
20180611124766
20180611124767
20180611124768
20180611124769
20180611124770
20180611124771
20180611124772
20180611124773
20180611124774
20180611124775
20180611124776
20180611124777
20180611124778
20180611124779
20180611124780
20180611124781
20180611124782
20180611124783
20180611124784
20180611124785
20180611124786
20180611124787
20180611124788
20180611124789
20180611124790
20180611124791
20180611124792
20180611124793
20180611124794
20180611124795
20180611124796
20180611124797
20180611124798
20180611124799
20180611124800
20180611124801
20180611124802
20180611124803
20180611124804
20180611124805
20180611124806
20180611124807
20180611124808
20180611124809
20180611124810
20180611124811
20180611124812
20180611124813
20180611124814
20180611124815
20180611124816
20180611124817
20180611124818
20180611124819
20180611124820
20180611124821
20180611124822
20180611124823
20180611124824
20180611124825
20180611124826
20180611124827
20180611124828
20180611124829
20180611124830
20180611124831
20180611124832
20180611124833
20180611124834
20180611124835
20180611124836
20180611124837
20180611124838
20180611124839
20180611124840
20180611124842
20180611124843
20180611124844
20180611124845
20180611124846
20180611124847
20180611124848
20180611124849
20180611124850
20180611124851
20180611124852
20180611124853
20180611124854
20180611124855
20180611124856
20180611124857
20180611124858
20180611124859
20180611124860
20180611124861
20180611124862
20180611124863
20180611124864
20180611124865
20180611124866
20180611124867
20180611124868
20180611124869
20180611124870
20180611124871
20180611124872
20180611124873
20180611124874
20180611124875
20180611124876
20180611124877
20180611124878
20180611124879
20180611124880
20180611124881
20180611124882
20180611124883
20180611124884
20180611124885
20180611124886
20180611124887
20180611124888
20180611124889
20180611124890
20180611124891
20180611124892
20180611124893
20180611124894
20180611124895
20180611124896
20180611124897
20180611124898
20180611124899
20180611124900
20180611124901
20180611124902
20180611124903
20180611124904
20180611124905
20180611124906
20180611124907
20180611124908
20180611124909
20180611124910
20180611124911
20180611124912
20180611124913
20180611124914
20180611124915
20180611124916
20180611124917
20180611124918
20180611124919
20180611124920
20180611124921
20180611124922
20180611124923
20180611124924
20180611124925
20180611124926
20180611124927
20180611124928
20180611124929
20180611124930
20180611124931
20180611124932
20180611124933
20180611124934
20180611124935
20180611124936
20180611124937
20180611124938
20180611124939
20180611124940
20180611124941
20180611124942
20180611124943
20180611124944
20180611124945
20180611124946
20180611124947
20180611124948
20180611124949
20180611124950
20180611124951
20180611124952
20180611124953
20180611124954
20180611124955
20180611124956
20180611124957
20180611124958
20180611124959
20180611124960
20180611124961
20180611124962
20180611124963
20180611124964
20180611124965
20180611124966
20180611124967
20180611124968
20180611124969
20180611124970
20180611124971
20180611124972
20180611124973
20180611124974
20180611124975
20180611124976
20180611124977
20180611124978
20180611124979
20180611124980
20180611124981
20180611124982
20180611124983
20180611124984
20180611124985
20180611124986
20180611124987
20180611124988
20180611124989
20180611124990
20180611124991
20180611124992
20180611124993
20180611124994
20180611124995
20180611124996
20180611124997
20180611124998
20180611124999
20180611125000
20180611125001
20180611125002
20180611125003
20180611125004
20180611125005
20180611125006
20180611125007
20180611125008
20180611125009
20180611125010
20180611125011
20180611125012
20180611126841
20180611142713
20180611142714
20180611142715
20180611142716
20180611142717
20180611142718
20180709170619
20181012230414
20181012230415
20181012230416
20181012230417
20181012230418
20181012230419
20181012230420
20181012230421
20181012230422
20181012230423
20181012230424
20181012230425
20181012230426
20181012230427
20181012230428
20181012230429
20181012230430
20181012230431
20181012230432
20181012230433
20181012230434
20181012230435
20181012230436
20181012230437
20181012230438
20181012230439
20181012230440
20181012230441
20181012230442
20181012230443
20181012230444
20181012230445
20181012230446
20181220220344
20181220220345
20181220220346
20181220220347
20181220220348
20181220220349
20181220220350
20181220220351
20181220220352
20181220220353
20181220220354
20181220220355
20181220220356
20181220220357
20181220220358
20181220220359
20181220220360
20181220220413
20181220220420
20181220220427
20181220220428
20181220220434
20181220220441
20181220220442
20181220220443
20181220220444
20181220220445
20181220220448
20181220220449
20181220220509
20181220220510
20181220220511
20181220220512
20181220220513
20181220220514
20181220220515
20181220220516
20190201194852
20190304203102
20190304203114
20190304203149
20190419230330
20190502162611
20190603100903
20190603100904
20190717132651
20190717132652
20190717132653
20190717132654
20190717132655
20190717132743
20190717132756
20190717132828
20191115143832
20191115143833
20191115143834
20200128153643
20200718151626
20200718151627
20200718151628
20200718151629
20200718151630
20200718151631
20200718151632
20200718151634
20200718151638
20200718151639
20200718151641
20200718151704
20200718151705
20200718151708
20200718151709
20200718151710
20200718151711
20200718151712
20200718153635
20200718153638
20200718153639
20200718153640
20200718153642
20200718153643
20200718153644
20200718153739
20200718153740
20200718153741
20200720153424
20200923121723
20200923121724
20200923121725
20200923121726
20200923121727
20200923121728
20200923121729
20200923121730
20200923121731
20200923121732
20200923121733
20200923121734
20200923121735
20200923121736
20200923121737
20200923121738
20200923121739
20200923121740
20200923121741
20200923121742
20200923121743
20200923121744
20200923121745
20200923121746
20200923121747
20200923121748
20200923121749
20200923121750
20200923121751
20200923121752
20200923121753
20200923121754
20200923121755
20200923121756
20200923121757
20200923121758
20200923121759
20200923121760
20200923121761
20200923121762
20201126165601
20201126165602
20201126165603
20201126165604
20201126165605
20201126165606
20201126165615
20201126165618
20201126165619
20201126165620
20201126165621
20201126165622
20201126165623
20201126165624
20201126165625
20201126165626
20201126165627
20201126165628
20201126165629
20201126165630
20201126165631
20201126165632
20201126165633
20201126165634
20201126165635
20201126165636
20201126165637
20201126165638
20201126165639
20201126165640
20201126165641
20201126165642
20201126165643
20201126165644
20201126165645
20201126165657
20210510225638
20210510225639
20210510225640
20210510225641
20210510225642
20210521003324
20210521003325
20210521003326
20210521003327
20210521003328
20210521003329
20210521003330
20210521003331
20210521003332
20210521003333
20210521003334
20210521003335
20210521003336
20210521003337
20210521003338
20210521003339
20210521003340
20210521003341
20210521003342
20210521003343
20210521003344
20210521003345
20210521003346
20210521003347
20210521003348
20210521003349
20210521003350
20210521003351
20210521003352
20210521003353
20210521003354
20210521003355
20210521003356
20210521003357
20210521003358
20210521003359
20210726155447
20210810114258
20210810114259
20210810114301
20210928081036
20210928081037
20211018123426
20220128174338
20220128181438
20220131105053
20220221135307
20220221135308
20220221135309
\.


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- PostgreSQL database dump complete
--

